//
//  RockDataStore.swift
//  RockExplorer
//
//  Created by Codex on 31/10/2568 BE.
//

import Foundation

enum RockDataStore {
    static var rocks: [Rock] {
        loadRocks()
    }

    private static func loadRocks() -> [Rock] {
        guard let url = Bundle.main.url(forResource: "rock_list", withExtension: "json") else {
            return RockDataStore.defaultRocks
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Rock].self, from: data)
        } catch {
            return RockDataStore.defaultRocks
        }
    }

    private static let defaultRocks: [Rock] = [
        Rock(
            id: 1,
            assetName: "granite",
            nameTH: "หินแกรนิต",
            nameEN: "Granite",
            nameSci: "Granite",
            type: "หินอัคนี",
            description: "เกิดจากการเย็นตัวของแมกมาใต้พื้นโลกอย่างช้า ๆ",
            meaning: "เป็นสัญลักษณ์ของความมั่นคงและแข็งแรง",
            location: nil
        ),
        Rock(
            id: 2,
            assetName: "basalt",
            nameTH: "หินบะซอลต์",
            nameEN: "Basalt",
            nameSci: "Basalt",
            type: "หินอัคนี",
            description: "เกิดจากลาวาที่เย็นตัวอย่างรวดเร็วบนพื้นผิวโลก",
            meaning: "สื่อถึงพลังของไฟและความแข็งแกร่ง",
            location: nil
        ),
        Rock(
            id: 3,
            assetName: "conglomerate",
            nameTH: "หินกรวดมน",
            nameEN: "Conglomerate",
            nameSci: "Conglomerate",
            type: "หินตะกอน",
            description: "เกิดจากการรวมตัวของกรวดและตะกอนที่ถูกกดทับ",
            meaning: "สื่อถึงความหลากหลายและความร่วมมือ",
            location: nil
        ),
        Rock(
            id: 4,
            assetName: "pumice",
            nameTH: "หินพัมมิซ",
            nameEN: "Pumice",
            nameSci: "Pumice",
            type: "หินอัคนี",
            description: "เกิดจากการเย็นตัวของลาวาที่มีฟองก๊าซมาก",
            meaning: "เบาแต่มีพลังในตัวเอง เหมือนแรงบันดาลใจ",
            location: nil
        )
    ]
}
