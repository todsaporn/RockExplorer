//
//  RockModelLoader.swift
//  RockExplorer
//
//  Created by Codex on 01/11/2568 BE.
//

import Foundation
import RealityKit
import UIKit

enum RockModelLoader {
    static func modelEntity(for rock: Rock) -> ModelEntity {
        if let url = resourceURL(for: rock.assetName, extension: "usdz") {
            if let entity = try? ModelEntity.loadModel(contentsOf: url) {
#if DEBUG
                print("RockModelLoader: loaded USDZ \(rock.assetName) from \(url.lastPathComponent)")
#endif
                entity.generateCollisionShapes(recursive: true)
                normalizeScale(for: entity)
                return entity
            } else {
                print("RockModelLoader: failed to load USDZ model for \(rock.assetName)")
            }
        }

        if let url = resourceURL(for: rock.assetName, extension: "reality") {
            if let entity = try? Entity.load(contentsOf: url) as? ModelEntity ?? Entity.load(contentsOf: url).convertToModelEntity() {
#if DEBUG
                print("RockModelLoader: loaded Reality file \(rock.assetName) from \(url.lastPathComponent)")
#endif
                entity.generateCollisionShapes(recursive: true)
                normalizeScale(for: entity)
                return entity
            } else {
                print("RockModelLoader: failed to load Reality file for \(rock.assetName)")
            }
        }

        if let url = resourceURL(for: rock.assetName, extension: "glb") {
            do {
                let entity = try Entity.load(contentsOf: url)
                let model = entity.convertToModelEntity()
#if DEBUG
                print("RockModelLoader: loaded GLB \(rock.assetName) from \(url.lastPathComponent)")
#endif
                model.generateCollisionShapes(recursive: true)
                normalizeScale(for: model)
                return model
            } catch {
                print("RockModelLoader: failed to load GLB model \(rock.assetName) - \(error.localizedDescription)")
            }
        } else {
            print("RockModelLoader: asset \(rock.assetName).glb not found in bundle")
        }

        return placeholderEntity()
    }

    private static func resourceURL(for name: String, extension ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Rocks") {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/Rocks") {
            return url
        }
        return nil
    }

    private static func normalizeScale(for entity: ModelEntity) {
        let size = entity.visualBounds(relativeTo: nil).extents
        let maxDimension = max(size.x, max(size.y, size.z))
        guard maxDimension > 0 else { return }
        let scaleFactor: Float = 0.3 / maxDimension
#if DEBUG
        print("RockModelLoader: normalizing scale. Extents=\(size) scaleFactor=\(scaleFactor)")
#endif
        entity.scale *= SIMD3<Float>(repeating: scaleFactor)
    }

    private static func placeholderEntity() -> ModelEntity {
        let mesh = MeshResource.generateBox(size: [0.12, 0.12, 0.12])
        let material = SimpleMaterial(color: UIColor.gray, isMetallic: false)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.generateCollisionShapes(recursive: true)
        return entity
    }
}

private extension Entity {
    func convertToModelEntity() -> ModelEntity {
        if let model = self as? ModelEntity {
            return model
        }

        let childrenModels = children.compactMap { $0 as? ModelEntity }
        if childrenModels.count == 1, let model = childrenModels.first {
            return model
        }

        let model = ModelEntity()
        children.forEach { child in
            model.addChild(child)
        }
        return model
    }
}
