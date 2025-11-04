//
//  ProximityHapticController.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import Foundation
import UIKit
import Combine

@MainActor
final class ProximityHapticController: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    private var timer: Timer?
    private var currentInterval: TimeInterval = 0
    private var currentIntensity: CGFloat = 0.5
    private let generator = UIImpactFeedbackGenerator(style: .medium)

    func update(distance: Double?) {
        guard let distance else {
            stop()
            return
        }

        let clamped = max(0, min(distance, 50))
        let normalized = 1 - (clamped / 50) // 0 : ≥50m, 1 : at target

        guard normalized > 0 else {
            stop()
            return
        }

        let interval = max(0.25, 1.0 - 0.6 * normalized)
        currentIntensity = max(0.3, normalized)

        if timer == nil || abs(interval - currentInterval) > 0.05 {
            startTimer(interval: interval)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func startTimer(interval: TimeInterval) {
        stop()
        currentInterval = interval
        generator.prepare()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.generator.impactOccurred(intensity: self.currentIntensity)
            self.generator.prepare()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
}
