//
//  UnityPack.swift
//  UnityPack-Swift
//
//  Created by Benjamin Michotte on 3/01/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

public class UnityPack {
    
    private static var env: UnityEnvironment?;
    
    public static func load(withFilePath filePath: String) throws -> AssetBundle? {
        if let e = env {
            return try e.load(filePath);
        } else {
            env = UnityEnvironment();
            return try env?.load(filePath);
        }
    }
    
    public static func extractData(asset: Asset, filterIds: [String]? = nil) -> (cards: [(path: String, tile: Any?)], textures: [String: ObjectPointer]) {
        var cards = [(path: String, tile: Any?)]()
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
                    cards.append((path: "", tile: nil))
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
                
                if let tile = carddef["m_DeckCardBarPortrait"] as? ObjectPointer {
                    let material = tile.resolve() as? Material
                    //cards.append((path: path.lowercased(), tile: material.savedProperties))
                } else {
                    cards.append((path: path.lowercased(), tile: nil))
                }
            }
        }
        
        
        
        return (cards, textures)
    }
    
}
