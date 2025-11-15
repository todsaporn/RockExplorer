//
//  RockImageProvider.swift
//  RockExplorer
//
//  Created by Codex on 01/11/2568 BE.
//

import UIKit

enum RockImageProvider {
    static func image(for rock: Rock) -> UIImage? {
        if let url = RockResourceResolver.resourceURL(for: rock.assetName, extension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        if let assetImage = UIImage(named: rock.assetName) {
            return assetImage
        }

        let fallbackName = RockResourceResolver.imageName(for: rock.assetName)
        if let url = RockResourceResolver.resourceURL(for: fallbackName, extension: "png"),
           let image = UIImage(contentsOfFile: url.path) {
            return image
        }

        if let fallbackImage = UIImage(named: fallbackName) {
            return fallbackImage
        }

        return nil
    }
}
