//
//  UnityEnvironment.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 05/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

public class UnityEnvironment {
    
    private var base_path: String;
    
    /** Cache bundles */
    private var bundles = [String : AssetBundle]()
    private var assets = [String : Asset]()
    
    init(base_path: String = "") {
        self.base_path = base_path
    }
    
    public var description: String { return "\(String(describing: UnityEnvironment.self)) (base_path: \(self.base_path))" }
    
    public func load(_ filePath: String) throws -> AssetBundle {
        // return from cache
        if let cached = bundles.values.first(where: { $0.path == filePath }) {
            return cached;
        }
        
        let ret = AssetBundle(self)
        try ret.load(filePath)
        
        // save to cache
        if let s = ret.name {
            self.bundles[s.lowercased()] = ret
            for asset: Asset in ret.assets {
                self.assets[asset.name.lowercased()] = asset
            }
        }
        
        
        return ret
    }
}
