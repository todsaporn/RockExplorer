//
//  RockCollectionViewModel.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import Foundation
import Combine

@MainActor
final class RockCollectionViewModel: ObservableObject {
    @Published private(set) var allRocks: [Rock] = RockDataStore.rocks
    @Published private var collectedRockIDs: Set<Int> = []

    private let storageKey = "collected_rock_ids"

    init() {
        loadCollectedRocks()
    }

    var collectedRocks: [Rock] {
        allRocks
            .filter { collectedRockIDs.contains($0.id) }
            .sorted { $0.nameEN < $1.nameEN }
    }

    var uncollectedRocks: [Rock] {
        allRocks
            .filter { !collectedRockIDs.contains($0.id) }
            .sorted { $0.nameEN < $1.nameEN }
    }

    func isCollected(_ rock: Rock) -> Bool {
        collectedRockIDs.contains(rock.id)
    }

    func collect(_ rock: Rock) {
        guard !isCollected(rock) else { return }
        collectedRockIDs.insert(rock.id)
        saveCollectedRocks()
    }

    private func loadCollectedRocks() {
        let ids = UserDefaults.standard.array(forKey: storageKey) as? [Int] ?? []
        collectedRockIDs = Set(ids)
    }

    private func saveCollectedRocks() {
        UserDefaults.standard.set(Array(collectedRockIDs), forKey: storageKey)
    }

    func resetCollection() {
        collectedRockIDs.removeAll()
        saveCollectedRocks()
    }
}
