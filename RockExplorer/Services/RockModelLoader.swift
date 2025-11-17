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
    private static var cache: [String: ModelEntity] = [:]
    private static let cacheQueue = DispatchQueue(label: "RockModelLoader.cacheQueue", attributes: .concurrent)
    private static let preloadQueue = DispatchQueue(label: "RockModelLoader.preloadQueue")

    static func modelEntity(for rock: Rock) -> ModelEntity {
        if let cached = cachedEntity(for: rock.assetName) {
            return cached.clone(recursive: true)
        }

        let entity = loadAndCacheModel(for: rock)
        return entity.clone(recursive: true)
    }

    static func preloadModel(for rock: Rock) {
        preloadQueue.async {
            if cachedEntity(for: rock.assetName) == nil {
                _ = loadAndCacheModel(for: rock)
            }
        }
    }

    private static func cachedEntity(for name: String) -> ModelEntity? {
        var result: ModelEntity?
        cacheQueue.sync {
            result = cache[name]
        }
        return result
    }

    private static func store(_ entity: ModelEntity, for name: String) {
        cacheQueue.async(flags: .barrier) {
            cache[name] = entity
        }
    }

    private static func loadAndCacheModel(for rock: Rock) -> ModelEntity {
        let entity = loadModel(for: rock)
        store(entity, for: rock.assetName)
        return entity
    }

    private static func loadModel(for rock: Rock) -> ModelEntity {
        let assetName = RockResourceResolver.modelName(for: rock.assetName)
        if let url = RockResourceResolver.resourceURL(for: assetName, extension: "usdz") {
            if let entity = loadUSDZModel(at: url) {
#if DEBUG
                print("RockModelLoader: loaded USDZ \(assetName) from \(url.lastPathComponent)")
#endif
                entity.generateCollisionShapes(recursive: true)
                normalizeScale(for: entity)
                return entity
            } else {
                print("RockModelLoader: failed to load USDZ model for \(assetName)")
            }
        }

        if let url = RockResourceResolver.resourceURL(for: rock.assetName, extension: "reality") {
            if let entity = loadRealityEntity(at: url)?.convertToModelEntity() {
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

        return placeholderEntity()
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

    private static func loadUSDZModel(at url: URL) -> ModelEntity? {
        var result: ModelEntity?
        let work = {
            result = try? ModelEntity.loadModel(contentsOf: url)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
        return result
    }

    private static func loadRealityEntity(at url: URL) -> Entity? {
        var result: Entity?
        let work = {
            result = try? Entity.load(contentsOf: url)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync(execute: work)
        }
        return result
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
