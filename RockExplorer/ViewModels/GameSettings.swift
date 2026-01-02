//
//  GameSettings.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import Foundation
import Combine

@MainActor
final class GameSettings: ObservableObject {
    @Published var detectionRadius: Double {
        didSet { save() }
    }

    @Published var searchRadius: Double {
        didSet { save() }
    }

    private let detectionKey = "settings_detection_radius"
    private let searchKey = "settings_search_radius"

    init() {
        detectionRadius = UserDefaults.standard.object(forKey: detectionKey) as? Double ?? 5
        searchRadius = UserDefaults.standard.object(forKey: searchKey) as? Double ?? 50
    }

    private func save() {
        UserDefaults.standard.set(detectionRadius, forKey: detectionKey)
        UserDefaults.standard.set(searchRadius, forKey: searchKey)
    }
}
