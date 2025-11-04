//
//  RockARView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI
import ARKit
import RealityKit

struct RockARView: View {
    let rock: Rock

    @EnvironmentObject private var collection: RockCollectionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var resetTrigger = false
    @State private var showCollectedToast = false
    @State private var isFocusMode = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(rock: rock, resetTrigger: $resetTrigger, isFocusMode: $isFocusMode)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                topBar
                if showCollectedToast {
                    collectionBanner
                }
                if isFocusMode {
                    focusBadge
                }
                Spacer()
                instructionCard
                actionBar
            }
            .padding()
        }
        .background(Color.black.opacity(0.4))
        .onAppear {
            if !collection.isCollected(rock) {
                collection.collect(rock)
            }
            showCollectedToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showCollectedToast = false
            }
        }
        .onDisappear {
            resetTrigger = true
            isFocusMode = false
        }
        .animation(.easeInOut(duration: 0.3), value: showCollectedToast)
        .animation(.easeInOut(duration: 0.3), value: isFocusMode)
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(rock.nameTH)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text(rock.nameEN)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            Text(rock.type)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
        }
    }

    private var collectionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.pastelGreen)
            VStack(alignment: .leading, spacing: 4) {
                Text("บันทึกใน RockDex แล้ว")
                    .font(.headline)
                Text(rock.nameTH)
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var focusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
            Text("Focus Mode")
            Spacer()
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.8), in: Capsule())
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("วิธีการควบคุม")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Label("ใช้สองนิ้วเพื่อซูมเข้า-ออก", systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
                .foregroundStyle(Color.secondaryText)

            Label("ลากหนึ่งนิ้วเพื่อหมุนหิน", systemImage: "arrow.triangle.2.circlepath")
                .foregroundStyle(Color.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.9))
        )
    }

    private var actionBar: some View {
        HStack(spacing: 16) {
            Button {
                if isFocusMode {
                    isFocusMode = false
                } else {
                    resetTrigger.toggle()
                }
            } label: {
                Label(isFocusMode ? "วางที่พื้น" : "Reset", systemImage: isFocusMode ? "cube.fill" : "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.white.opacity(0.85))
                    )
            }
            .buttonStyle(.plain)

            Button {
                isFocusMode.toggle()
            } label: {
                Label(isFocusMode ? "ปิด Focus" : "Focus", systemImage: isFocusMode ? "xmark.circle.fill" : "scope")
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
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ARViewContainer: UIViewRepresentable {
    let rock: Rock
    @Binding var resetTrigger: Bool
    @Binding var isFocusMode: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(rock: rock)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.automaticallyConfigureSession = false

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)

        context.coordinator.updateRock(rock, in: arView)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateRock(rock, in: uiView)

        if resetTrigger {
            context.coordinator.resetModelPosition()
            DispatchQueue.main.async {
                resetTrigger = false
            }
        }

        context.coordinator.setFocusMode(isFocusMode)
    }

    final class Coordinator {
        private(set) var currentAssetName: String?
        private weak var arView: ARView?
        private var anchor: AnchorEntity?
        private var modelEntity: ModelEntity?
        private var originalTransform: Transform?
        private var focusAnchor: AnchorEntity?
        private var isFocusMode = false
        private var currentRock: Rock

        init(rock: Rock) {
            currentAssetName = rock.assetName
            currentRock = rock
        }

        func updateRock(_ rock: Rock, in arView: ARView) {
            self.arView = arView
            if currentAssetName != rock.assetName || modelEntity == nil {
                installModel(in: arView, rock: rock)
            }
        }

        private func installModel(in arView: ARView, rock: Rock) {
            currentAssetName = rock.assetName
            currentRock = rock
            isFocusMode = false

            arView.scene.anchors.removeAll()
            anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
            focusAnchor = nil

            let model = RockModelLoader.modelEntity(for: rock)
            modelEntity = model
            originalTransform = model.transform
            anchor?.addChild(model)
            if let anchor {
                arView.scene.addAnchor(anchor)
            }
            arView.installGestures([.translation, .rotation, .scale], for: model)
        }

        func resetModelPosition() {
            guard let modelEntity, let originalTransform else { return }
            modelEntity.transform = originalTransform
        }

        func setFocusMode(_ enabled: Bool) {
            guard let arView, let modelEntity else { return }
            guard enabled != isFocusMode else { return }

            if enabled {
                anchor?.removeChild(modelEntity)
                arView.scene.anchors.removeAll()
                let cameraTransform = arView.cameraTransform
                let forwardColumn = cameraTransform.matrix.columns.2
                let forward = SIMD3<Float>(forwardColumn.x, forwardColumn.y, forwardColumn.z)
                var position = cameraTransform.translation
                position -= forward * 0.5
                let focusAnchor = AnchorEntity(world: position)
                focusAnchor.addChild(modelEntity)
                modelEntity.orientation = cameraTransform.rotation
                arView.scene.addAnchor(focusAnchor)
                self.focusAnchor = focusAnchor
                isFocusMode = true
            } else {
                installModel(in: arView, rock: currentRock)
            }
        }

    }
}

#Preview {
    RockARView(rock: RockDataStore.rocks.first ?? .placeholder)
        .environmentObject(RockCollectionViewModel())
}
