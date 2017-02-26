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
    
    public static func extractData(asset: Asset) -> (cards: [Any], textures: [String: ObjectPointer]) {
        var cards = [Any]()
        var textures = [String: ObjectPointer]()
        
        for obj in asset.objects.values {
            
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
                print(d)
                /*if let d = GameObject(obj.read() as? [String: Any]) {
                    
                }*/
                
            }
            
            //print("object: \(obj)")
        }
        
        
        
        return (cards, textures)
    }
    
}
