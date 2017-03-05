//
//  UnityPack.swift
//  UnityPack-Swift
//
//  Created by Benjamin Michotte on 3/01/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

// allows adding dictionaries
private func +=<K, V> ( left: inout [K : V], right: [K : V]) { for (k, v) in right { left[k] = v } }

public class UnityPack {
    
    private var env: UnityEnvironment?
    
    //let resourceFiles = ["cardtextures0", "cards0", "cardxml0"]
    
    private var allCards = [String: (path: String, tile: Any?)]()
    private var allTextures = [String: ObjectPointer]()
    
    public init?(with hearthstonePath: String) {
        do {
        // process all .unity3d files
        let fileManager = FileManager.default
        let rootPath = hearthstonePath + "/Data/OSX/"
        try fileManager.enumerator(atPath: rootPath)?.forEach({ (e) in
            if let e = e as? String, let url = URL(string: e) {
                if url.pathExtension == "unity3d" && (e.range(of:"cards") != nil || e.range(of:"cardtextures") != nil
                    || e.range(of:"cardxml") != nil) {
                    print("Loading \(e)")
                    if let bundle = try load(withFilePath: rootPath + e) {
                        
                        for asset in bundle.assets {
                            print("Parsing asset \(asset.name)")
                            let (cards, textures) = extractCardsAndTextures(asset: asset)
                            allCards += cards
                            allTextures += textures
                        }
                    }
                }
            }
        })

        let paths = allCards.map {$0.value.path}
        print("Found \(allCards.count) cards, \(allTextures.count) textures including \(Set(paths).count) unique in use.")

        } catch let error {
            print("\(error)")
            return nil
        }
    }

    public func getTexture(cardid: String) -> (NSImage?, [String: Any?]?) {
        guard let (path, tile) = allCards[cardid] else {
            print("No card found with id \(cardid)")
            return (nil, nil)
        }
        
        guard let pptr = allTextures[path] else {
            print("Path not found for \(cardid)")
            return (nil, nil)
        }
        
        guard let texture = pptr.resolve() as? Texture2D, let image = texture.image else {
            print("Image data cannot be resolved")
            return (nil, nil)
        }
        
        if let tileDict = tile as? [String: Any?] {
            return (image, tileDict)
        }
        return (image, nil)
    }

    private func load(withFilePath filePath: String) throws -> AssetBundle? {
        if let e = env {
            return try e.load(filePath);
        } else {
            env = UnityEnvironment();
            return try env?.load(filePath);
        }
    }
    
    private func extractCardsAndTextures(asset: Asset, filterIds: [String]? = nil) -> (cards: [String: (path: String, tile: Any?)], textures: [String: ObjectPointer]) {
        var cards = [String: (path: String, tile: Any?)]()
        var textures = [String: ObjectPointer]()
        
        let objects = asset.objects
        for obj in objects.values {
            
            if obj.type == "AssetBundle" {
                if let dict = obj.read() as? [String: Any], let items = dict["m_Container"] as? [(first: Any?, second: Any?)] {
                        for item in items {
                            var path = (item.first as! String).lowercased()
                            if let obj = item.second as? [String: Any], let asset = obj["asset"] as? ObjectPointer {
                                if !path.hasPrefix("final/") {
                                    path = "final/" + path
                                }
                                if !path.hasPrefix("final/assets") {
                                    continue
                                }
                                textures[path] = asset
                            }
                        }
                }
            }
            
            else if obj.type == "GameObject" {
                let d = obj.read() as! GameObject
                let cardid = d.name
                if let filters = filterIds {
                    if !filters.contains(cardid) {
                        continue
                    }
                }
                if ["CardDefTemplate", "HiddenCard"].contains(cardid) {
                    // not a real card
                    cards[cardid] = (path: "", tile: nil)
                    continue
                }
                if d.component.count < 2 {
                    // not a real card
                    continue
                }
                guard let carddef = d.component[1].1.resolve() as? [String:Any?] else {
                    continue
                }
                
                guard var path = carddef["m_PortraitTexturePath"] as? String else {
                    continue
                }
                
                if path == "" {
                    continue
                }
                
                path = "final/" + path
                
                if let tile = carddef["m_DeckCardBarPortrait"] as? ObjectPointer, let material = tile.resolve() as? Material {
                    cards[cardid] = (path: path.lowercased(), tile: material.savedProperties)
                } else {
                    cards[cardid] = (path: path.lowercased(), tile: nil)
                }
            }
        }
 
        return (cards, textures)
    }
    
}
