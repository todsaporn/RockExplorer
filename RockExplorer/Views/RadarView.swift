//
//  RadarView.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct RadarView: View {
    private let onReady: (() -> Void)?

    init(onReady: (() -> Void)? = nil) {
        self.onReady = onReady
    }

    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var radarViewModel: RadarViewModel
    @EnvironmentObject private var collection: RockCollectionViewModel
    @EnvironmentObject private var settings: GameSettings

    @StateObject private var hapticController = ProximityHapticController()
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var hasGeneratedRocks = false
    @State private var focusRock: Rock?
    @State private var showFocusIntro = false
    @State private var isLoading = true
    @State private var loadingAction = "กำลังเตรียมโหมด Radar"
    @State private var loadingWaiting = "รอสัญญาณตำแหน่งของคุณ"
    @State private var loadingProgress: Double = 0
    @State private var loadingTask: Task<Void, Never>?
    @State private var loadingCompletionWork: DispatchWorkItem?
    @State private var proximityLevel: ProximityLevel = .searching
    @State private var targetBearing: Double?
    @State private var nearestDistance: Double?
    @State private var showsHintPanel = true

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                UserAnnotation()
                ForEach(radarViewModel.radarRocks) { radarRock in
                    Annotation(radarRock.annotationTitle, coordinate: radarRock.coordinate) {
                        RockAnnotationView(radarRock: radarRock)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
            .onAppear {
                startLoading(action: "กำลังเตรียมโหมด Radar", waiting: "รอสัญญาณตำแหน่งของคุณ", resetProgress: true)
                locationService.requestAccess()
                locationService.startUpdates()
                onReady?()
            }
            .onDisappear {
                locationService.stopUpdates()
                radarViewModel.reset()
                hapticController.stop()
                cancelLoading()
                targetBearing = nil
                nearestDistance = nil
            }
            .onReceive(locationService.$userLocation.compactMap { $0 }) { location in
                updateMap(with: location)
            }

            ZStack {
                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            Spacer()
                            RadarStatusCard(
                                heading: locationService.heading,
                                targetBearing: targetBearing,
                                distance: nearestDistance,
                                level: proximityLevel
                            )
                            .frame(maxWidth: 340)
                            Spacer()
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 12)

                    Spacer()

                    if showsHintPanel {
                        RadarHintView(searchRadius: settings.searchRadius, detectionRadius: settings.detectionRadius)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showsHintPanel.toggle() } }) {
                    Image(systemName: "info")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.surface.opacity(0.92))
                                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4)
                        )
                }
                .padding(.trailing, 12)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }

            if isLoading {
                LoadingPanel(action: loadingAction, waiting: loadingWaiting, progress: loadingProgress)
            }
        }
        .navigationTitle("Radar Mode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Radar Mode")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.primaryText)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: recenterCamera) {
                    Image(systemName: "location.circle.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.primaryText)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(Color.surface.opacity(0.92))
                                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
                        )
                }
            }
        }
        .fullScreenCover(item: $focusRock, onDismiss: handleFocusDismiss) { rock in
            RockFocusView(rock: rock, showsCongratulationPanel: showFocusIntro)
                .onDisappear {
                    showFocusIntro = false
                }
        }
    }

    private func updateMap(with location: CLLocation) {
        if !hasGeneratedRocks {
            startLoading(
                action: "กำลังสุ่มตำแหน่งหินรอบตัว",
                waiting: "ประมวลผลพื้นที่ \(Int(settings.searchRadius)) เมตร",
                resetProgress: false
            )
            radarViewModel.prepareRocks(
                around: location,
                searchRadius: settings.searchRadius,
                minimumDistance: settings.detectionRadius
            )
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: settings.searchRadius * 4,
                    longitudinalMeters: settings.searchRadius * 4
                )
            )
            hasGeneratedRocks = true
        }

        if focusRock != nil || showFocusIntro {
            hapticController.stop()
            return
        }

        let result = radarViewModel.updateUserLocation(location, detectionRadius: settings.detectionRadius)
        nearestDistance = result.nearestDistance
        updateTargetBearing(with: location, rock: result.nearestRock)

        if let discovered = result.found {
            if !collection.isCollected(discovered.rock) {
                collection.collect(discovered.rock)
            }
            updateProgress(for: 0.0)
            showFocusIntro = true
            focusRock = discovered.rock
            hapticController.stop()
            updateProximityStatus(distance: 0)
            finishLoading()
        } else {
            if let distance = result.nearestDistance {
                hapticController.update(distance: distance, maxRange: settings.searchRadius)
                updateProgress(for: distance)
                updateProximityStatus(distance: distance)
            } else {
                hapticController.stop()
                updateProximityStatus(distance: nil)
            }
            finishLoading()
        }
    }

    private func handleFocusDismiss() {
        showFocusIntro = false
        if radarViewModel.consumeNearbyRock() != nil {
            hasGeneratedRocks = false
            startLoading(action: "กำลังวางตำแหน่งหินใหม่", waiting: "รอสัญญาณการเคลื่อนที่", resetProgress: true)
        }
    }

    private func updateTargetBearing(with location: CLLocation, rock: RadarRock?) {
        guard let rock else {
            targetBearing = nil
            return
        }

        targetBearing = bearing(from: location.coordinate, to: rock.coordinate)
    }

    private func bearing(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let lat1 = origin.latitude.toRadians
        let lon1 = origin.longitude.toRadians
        let lat2 = destination.latitude.toRadians
        let lon2 = destination.longitude.toRadians
        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radians = atan2(y, x)
        let degrees = radians * 180 / .pi
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        return normalized >= 0 ? normalized : (normalized + 360)
    }

    private func recenterCamera() {
        guard let location = locationService.userLocation else { return }
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    latitudinalMeters: settings.searchRadius * 4,
                    longitudinalMeters: settings.searchRadius * 4
                )
            )
        }
    }

    private func startLoading(action: String, waiting: String, resetProgress: Bool) {
        loadingCompletionWork?.cancel()
        loadingCompletionWork = nil
        loadingAction = action
        loadingWaiting = waiting
        proximityLevel = .searching
        if resetProgress {
            loadingProgress = 0
            loadingTask?.cancel()
            loadingTask = nil
        }
        if loadingTask == nil {
            loadingTask = Task { @MainActor in
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 250_000_000)
                    if Task.isCancelled { break }
                    loadingProgress = min(loadingProgress + Double.random(in: 3...7), 95)
                }
            }
        }
        withAnimation {
            isLoading = true
        }
    }

    private func updateProgress(for distance: Double?) {
        guard let distance else { return }
        let range = max(settings.searchRadius, 1)
        let clamped = max(0, min(range, distance))
        let normalized = 1 - (clamped / range)
        let computed = normalized * 100
        loadingProgress = max(loadingProgress, computed)
    }

    private func finishLoading() {
        guard isLoading else { return }
        loadingTask?.cancel()
        loadingTask = nil
        loadingProgress = 100
        loadingAction = "พร้อมใช้งาน"
        loadingWaiting = "พบตำแหน่งเรียบร้อย"
        loadingCompletionWork?.cancel()
        let work = DispatchWorkItem {
            withAnimation {
                isLoading = false
            }
        }
        loadingCompletionWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func cancelLoading() {
        loadingTask?.cancel()
        loadingTask = nil
        loadingCompletionWork?.cancel()
        loadingCompletionWork = nil
        withAnimation {
            isLoading = false
        }
    }

    private func updateProximityStatus(distance: Double?) {
        guard let distance else {
            proximityLevel = .searching
            return
        }

        let arrivalThreshold = settings.detectionRadius
        let nearThreshold = min(settings.searchRadius, arrivalThreshold * 3)
        let mediumThreshold = min(settings.searchRadius, arrivalThreshold * 6)

        if distance <= arrivalThreshold {
            proximityLevel = .arrived
        } else if distance <= nearThreshold {
            proximityLevel = .near
        } else if distance <= mediumThreshold {
            proximityLevel = .medium
        } else {
            proximityLevel = .far
        }
    }
}

private struct RockAnnotationView: View {
    let radarRock: RadarRock

    var body: some View {
        if radarRock.isDiscovered {
            Text(radarRock.rock.nameTH)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.pastelGreen.gradient)
                        .shadow(radius: 4)
                )
        } else {
            ZStack {
                Circle()
                    .fill(Color.pastelPurple)
                    .frame(width: 32, height: 32)
                    .shadow(radius: 4)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 2)
                    )

                Text("?")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
    }
}

private enum ProximityLevel {
    case searching
    case far
    case medium
    case near
    case arrived

    var description: String {
        switch self {
        case .searching:
            return "กำลังค้นหาตำแหน่ง"
        case .far:
            return "ยังไกลจากหิน"
        case .medium:
            return "เข้าใกล้ขึ้นแล้ว"
        case .near:
            return "ใกล้ถึงหินมากแล้ว"
        case .arrived:
            return "ถึงจุดหินแล้ว!"
        }
    }

    var iconName: String {
        switch self {
        case .searching:
            return "location"
        case .far:
            return "location.north.line"
        case .medium:
            return "location.north.line.fill"
        case .near:
            return "location.circle"
        case .arrived:
            return "location.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .searching:
            return Color.secondaryText
        case .far:
            return Color.pastelPurple
        case .medium:
            return Color.pastelBlue
        case .near:
            return Color.pastelGreen
        case .arrived:
            return Color.primaryText
        }
    }
}

private struct LoadingPanel: View {
    let action: String
    let waiting: String
    let progress: Double

    var body: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(action)
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)

                    Text("รอ: \(waiting)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                }

                ProgressView(value: min(progress, 100), total: 100)
                    .progressViewStyle(.linear)
                    .tint(Color.pastelPurple)
                    .frame(height: 8)
                    .clipShape(Capsule())

                Text(String(format: "%.0f%%", min(progress, 100)))
                    .font(.footnote.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primaryText)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.surface)
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 8)
            )
            .padding(.horizontal, 48)
        }
    }
}

private struct RadarStatusCard: View {
    let heading: CLHeading?
    let targetBearing: Double?
    let distance: Double?
    let level: ProximityLevel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ทิศทางใกล้สุด")
                        .font(.caption2)
                        .foregroundStyle(Color.secondaryText)
                    HStack(spacing: 6) {
                        Text(directionLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.secondaryText)
                        Spacer()
                        Text(distanceLabel)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.surfaceSoft)
                        .frame(height: 64)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)

                    Image(systemName: "location.north.line.fill")
                        .font(.title)
                        .foregroundStyle(targetBearing == nil ? Color.primaryText : Color.pastelPurple)
                        .rotationEffect(.degrees(pointerRotationDegrees))
                        .animation(.easeInOut(duration: 0.2), value: pointerRotationDegrees)
                }
            }

            Text(level.description)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var pointerRotationDegrees: Double {
        if let bearing = targetBearing {
            return bearing
        }
        return heading?.trueHeading ?? 0
    }

    private var directionLabel: String {
        guard let bearing = targetBearing else {
            if let headingValue = heading?.trueHeading {
                return "กำลังหันไปทาง \(cardinalDirection(for: headingValue)) • \(Int(headingValue))°"
            }
            return "กำลังค้นหาเป้าหมาย"
        }
        return "\(cardinalDirection(for: bearing)) • \(Int(bearing))°"
    }

    private var distanceLabel: String {
        guard let distance else {
            return "รอระบุระยะจากหิน"
        }
        if distance >= 1000 {
            let km = distance / 1000
            return String(format: "ห่าง %.1f กม.", km)
        } else {
            return String(format: "ห่าง %.0f ม.", distance)
        }
    }

    private func cardinalDirection(for bearing: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int(((bearing + 22.5) / 45).rounded(.down)) % directions.count
        return directions[index]
    }
}

private struct RadarHintView: View {
    let searchRadius: Double
    let detectionRadius: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("เดินเข้าใกล้หินในรัศมี \(searchRadiusLabel) เมตร แล้วปลดล็อกเมื่ออยู่ไม่เกิน \(detectionRadiusLabel) เมตร")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primaryText)

            Text("เคล็ดลับ: เดินช้า ๆ แล้วสังเกตแรงสั่นที่ถี่และแรงขึ้นเมื่อเข้าใกล้ตำแหน่งปริศนา")
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var searchRadiusLabel: String {
        searchRadius.formatted(.number.precision(.fractionLength(0)))
    }

    private var detectionRadiusLabel: String {
        detectionRadius.formatted(.number.precision(.fractionLength(0...1)))
    }
}

private extension Double {
    var toRadians: Double {
        self * .pi / 180
    }
}

#Preview {
    NavigationStack {
        let collection = RockCollectionViewModel()
        let settings = GameSettings()
        RadarView()
            .environmentObject(LocationService())
            .environmentObject(RadarViewModel(collection: collection))
            .environmentObject(collection)
            .environmentObject(settings)
    }
}
