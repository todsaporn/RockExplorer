//
//  RadarViewModel.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import CoreLocation
import Combine

@MainActor
final class RadarViewModel: ObservableObject {
    @Published private(set) var radarRocks: [RadarRock] = []
    @Published var nearbyRock: RadarRock?

    private let collection: RockCollectionViewModel
    private var isGenerating = false

    init(collection: RockCollectionViewModel) {
        self.collection = collection
    }

    func reset() {
        radarRocks = []
        nearbyRock = nil
        isGenerating = false
    }

    func prepareRocks(around location: CLLocation) {
        guard !isGenerating else { return }
        isGenerating = true

        var updatedRocks: [RadarRock] = []
        for rock in collection.allRocks {
            if var existing = radarRocks.first(where: { $0.rock.id == rock.id }) {
                existing.isDiscovered = existing.isDiscovered || collection.isCollected(rock)
                updatedRocks.append(existing)
            } else {
                let coordinate = Self.randomCoordinate(around: location)
                updatedRocks.append(
                    RadarRock(
                        rock: rock,
                        coordinate: coordinate,
                        isDiscovered: collection.isCollected(rock)
                    )
                )
            }
        }

        radarRocks = updatedRocks
        isGenerating = false
    }

    func updateUserLocation(_ location: CLLocation) -> (found: RadarRock?, nearestDistance: Double?, nearestRock: RadarRock?) {
        guard !radarRocks.isEmpty else { return (nil, nil, nil) }

        var closestRock: RadarRock?
        var updatedRocks = radarRocks
        var nearestDistance: Double?
        var nearestRock: RadarRock?

        for index in updatedRocks.indices {
            let radarRock = updatedRocks[index]
            let rockLocation = CLLocation(latitude: radarRock.coordinate.latitude, longitude: radarRock.coordinate.longitude)
            let distance = location.distance(from: rockLocation)

            if nearestDistance == nil || distance < nearestDistance ?? .greatestFiniteMagnitude {
                nearestDistance = distance
                nearestRock = updatedRocks[index]
            }

            if distance <= 5 && !updatedRocks[index].isDiscovered {
                updatedRocks[index].isDiscovered = true
                closestRock = updatedRocks[index]
            }
        }

        radarRocks = updatedRocks
        nearbyRock = closestRock
        return (closestRock, nearestDistance, nearestRock)
    }

    func consumeNearbyRock() -> RadarRock? {
        guard let rock = nearbyRock else { return nil }
        nearbyRock = nil
        return rock
    }

    static func randomCoordinate(around location: CLLocation, radius: Double = 50) -> CLLocationCoordinate2D {
        let bearing = Double.random(in: 0..<(2 * .pi))
        let distance = Double.random(in: 5...radius)

        let earthRadius = 6_371_000.0
        let latitude = location.coordinate.latitude * .pi / 180
        let longitude = location.coordinate.longitude * .pi / 180
        let angularDistance = distance / earthRadius

        let newLat = asin(
            sin(latitude) * cos(angularDistance) +
            cos(latitude) * sin(angularDistance) * cos(bearing)
        )

        let newLon = longitude + atan2(
            sin(bearing) * sin(angularDistance) * cos(latitude),
            cos(angularDistance) - sin(latitude) * sin(newLat)
        )

        return CLLocationCoordinate2D(
            latitude: newLat * 180 / .pi,
            longitude: newLon * 180 / .pi
        )
    }
}

struct RadarRock: Identifiable, Equatable {
    let id = UUID()
    let rock: Rock
    let coordinate: CLLocationCoordinate2D
    var isDiscovered: Bool = false

    static let sample = RadarRock(
        rock: Rock.placeholder,
        coordinate: CLLocationCoordinate2D(latitude: 13.736717, longitude: 100.523186)
    )

    static func == (lhs: RadarRock, rhs: RadarRock) -> Bool {
        lhs.id == rhs.id
    }

    var annotationTitle: String {
        isDiscovered ? rock.nameTH : "?"
    }
}
