//
//  RockFocusView.swift
//  RockExplorer
//
//  Created by Codex on 01/11/2568 BE.
//

import SwiftUI
import ARKit
import RealityKit
import UIKit

struct RockFocusView: View {
    let rock: Rock

    @Environment(\.dismiss) private var dismiss
    @State private var distance: Float = 0.5
    @State private var showCongratulationPanel: Bool

    init(rock: Rock, showsCongratulationPanel: Bool = false) {
        self.rock = rock
        _showCongratulationPanel = State(initialValue: showsCongratulationPanel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            FocusARContainer(rock: rock, distance: $distance)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                header
                Spacer()
                controls
            }
            .padding()

            if showCongratulationPanel {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                FocusCongratsPanel(rock: rock) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        showCongratulationPanel = false
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(Color.black.opacity(0.35))
        .preferredColorScheme(.light)
        .onAppear {
            RockModelLoader.preloadModel(for: rock)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Button("Close") {
                dismiss()
            }
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.85))
            )

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(rock.nameTH)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(rock.nameEN)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("โหมด Focus Mode")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Text("หมุนรอบจุดเพื่อดูโมเดลจากทุกมิติ ใช้สไลด์ปรับระยะใกล้/ไกลตามต้องการ")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading) {
                Text(String(format: "ระยะห่างจากกล้อง: %.2f ม.", distance))
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                Slider(value: Binding(
                    get: { Double(distance) },
                    set: { distance = Float($0) }
                ), in: 0.2...1.5, step: 0.05)
                    .tint(Color.pastelPurple)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.92))
        )
    }
}

#Preview {
    RockFocusView(rock: RockDataStore.rocks.first ?? .placeholder)
}

private struct FocusARContainer: UIViewRepresentable {
    let rock: Rock
    @Binding var distance: Float

    func makeCoordinator() -> Coordinator {
        Coordinator(rock: rock, distance: distance)
    }

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.automaticallyConfigureSession = false

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        configuration.environmentTexturing = .automatic
        view.session.run(configuration)

        context.coordinator.setup(in: view)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if context.coordinator.currentAssetName != rock.assetName {
            context.coordinator.setup(in: uiView, rock: rock)
        }
        context.coordinator.updateDistance(distance)
    }

    final class Coordinator {
        private(set) var currentAssetName: String
        private var currentRock: Rock
        private weak var arView: ARView?
        private var anchor = AnchorEntity(.camera)
        private var modelEntity: ModelEntity?
        private var distance: Float
        private var yaw: Float = 0
        private var pitch: Float = 0
        private var baseYaw: Float = 0
        private var basePitch: Float = 0
        private var panRecognizer: UIPanGestureRecognizer?

        init(rock: Rock, distance: Float) {
            currentAssetName = rock.assetName
            currentRock = rock
            self.distance = distance
        }

        func setup(in view: ARView, rock: Rock? = nil) {
            arView = view
            if let rock {
                currentRock = rock
                currentAssetName = rock.assetName
            }

            distance = max(distance, 0.2)

            view.scene.anchors.removeAll()
            anchor = AnchorEntity(.camera)
            view.scene.addAnchor(anchor)

            anchor.children.removeAll()

            let entity = RockModelLoader.modelEntity(for: currentRock)
            entity.position = SIMD3<Float>(0, 0, -distance)
            modelEntity = entity
            anchor.addChild(entity)
            view.installGestures([.rotation, .scale], for: entity)

            yaw = 0
            pitch = 0
            applyRotation(yaw: yaw, pitch: pitch, to: entity)

            if panRecognizer == nil {
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
                pan.maximumNumberOfTouches = 1
                view.addGestureRecognizer(pan)
                panRecognizer = pan
            }
        }

        func updateDistance(_ distance: Float) {
            self.distance = distance
            modelEntity?.position = SIMD3<Float>(0, 0, -distance)
        }

        @objc
        private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard let model = modelEntity else { return }
            let translation = recognizer.translation(in: recognizer.view)
            let deltaYaw = Float(translation.x) * 0.005
            let deltaPitch = -Float(translation.y) * 0.003

            switch recognizer.state {
            case .began:
                baseYaw = yaw
                basePitch = pitch
            case .changed:
                let newYaw = baseYaw + deltaYaw
                let newPitch = normalizeAngle(basePitch + deltaPitch)
                applyRotation(yaw: newYaw, pitch: newPitch, to: model)
            case .ended, .cancelled:
                yaw = baseYaw + deltaYaw
                pitch = normalizeAngle(basePitch + deltaPitch)
            default:
                break
            }
        }

        private func applyRotation(yaw: Float, pitch: Float, to model: ModelEntity) {
            let yawQuat = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
            let pitchQuat = simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0))
            model.orientation = yawQuat * pitchQuat
        }

        private func normalizeAngle(_ value: Float) -> Float {
            var angle = fmod(value, 2 * .pi)
            if angle > .pi {
                angle -= 2 * .pi
            } else if angle < -.pi {
                angle += 2 * .pi
            }
            return angle
        }
    }
}

private struct FocusCongratsPanel: View {
    let rock: Rock
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 48, height: 5)
                    .padding(.top, 8)

                VStack(spacing: 12) {
                    if let image = RockImageProvider.image(for: rock) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
                    } else if let placeholder = UIImage(named: "placeholder") {
                        Image(uiImage: placeholder)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
                    }

                    Text("พบหินใหม่!")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)

                    Text(rock.nameTH)
                        .font(.title3.bold())
                        .foregroundStyle(Color.primaryText)

                    Text(rock.nameEN)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                }

                VStack(alignment: .leading, spacing: 12) {
                    infoBlock(title: "ประเภทของหิน", value: rock.type)
                    infoBlock(title: "ความแข็ง (MOHS)", value: rock.hardness)
                    infoBlock(title: "เกิดได้อย่างไร", value: rock.description)
                    infoBlock(title: "การใช้งาน", value: rock.usage)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onDismiss) {
                    Label("ปิดแล้วเริ่ม Focus Mode", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.pastelPurple, .pastelBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.surface)
                .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 20)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    private func infoBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
            Text(value)
                .font(.body)
                .foregroundStyle(Color.primaryText)
        }
    }
}
