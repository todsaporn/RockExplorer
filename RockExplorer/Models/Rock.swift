//
//  Rock.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import Foundation
import CoreLocation

struct Rock: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let assetName: String
    let nameTH: String
    let nameEN: String
    let nameSci: String
    let type: String
    let description: String
    let meaning: String
    let location: CLLocationCoordinate2D?

    var imageName: String {
        "Resources/Rocks/\(assetName).png"
    }

    var modelName: String {
        "Resources/Rocks/\(assetName).glb"
    }

    static let placeholder = Rock(
        id: -1,
        assetName: "placeholder",
        nameTH: "ตัวอย่างหิน",
        nameEN: "Sample Rock",
        nameSci: "Sample Rock",
        type: "หินอัคนี",
        description: "ข้อมูลตัวอย่างสำหรับหน้าจอพรีวิว",
        meaning: "ความหมายตัวอย่าง",
        location: nil
    )
}

extension Rock {
    private enum CodingKeys: String, CodingKey {
        case id
        case assetName
        case nameTH
        case nameEN
        case nameSci
        case type
        case description
        case meaning
        case latitude
        case longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        assetName = try container.decode(String.self, forKey: .assetName)
        nameTH = try container.decode(String.self, forKey: .nameTH)
        nameEN = try container.decode(String.self, forKey: .nameEN)
        nameSci = try container.decode(String.self, forKey: .nameSci)
        type = try container.decode(String.self, forKey: .type)
        description = try container.decode(String.self, forKey: .description)
        meaning = try container.decode(String.self, forKey: .meaning)
        if let lat = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let lon = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            location = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(assetName, forKey: .assetName)
        try container.encode(nameTH, forKey: .nameTH)
        try container.encode(nameEN, forKey: .nameEN)
        try container.encode(nameSci, forKey: .nameSci)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(meaning, forKey: .meaning)
        if let location {
            try container.encode(location.latitude, forKey: .latitude)
            try container.encode(location.longitude, forKey: .longitude)
        }
    }
}

extension Rock {
    static func == (lhs: Rock, rhs: Rock) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
