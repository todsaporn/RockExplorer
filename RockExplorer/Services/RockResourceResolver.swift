//
//  RockResourceResolver.swift
//  RockExplorer
//
//  Created by Codex on 01/11/2568 BE.
//

import Foundation

enum RockResourceResolver {
    static func resourceURL(for name: String, extension ext: String) -> URL? {
        let bundle = Bundle.main
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Rocks") {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources/Rocks") {
            return url
        }
        return nil
    }

    static func hasResource(named name: String, extension ext: String) -> Bool {
        resourceURL(for: name, extension: ext) != nil
    }

    static func imageName(for assetName: String) -> String {
        // use breccia as default value
        hasResource(named: assetName, extension: "png") ? assetName : "breccia"
    }

    static func modelName(for assetName: String) -> String {
        // use breccia as default value
        hasResource(named: assetName, extension: "usdz") ? assetName : "breccia"
    }

}
