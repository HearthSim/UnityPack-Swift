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
    
    public func getAsset(fileName: String) -> Asset? {
        if let asset = assets[fileName] {
            return asset
        }
        
        let path = self.base_path + fileName
        if let asset = Asset(fromFile: path) {
            self.assets[fileName] = asset
        } else {
            self.discover(name: fileName)
            self.populateAssets()
            
            if let asset = assets[fileName] {
                return asset
            } else {
                print("Error: No such asset: \(fileName)");
                return nil
            }
        }
        return nil
    }
    
    func discover(name: String) {
        for bundle in self.bundles.values {
            if let bPath = bundle.path {
                let dirname = (bPath as NSString).deletingLastPathComponent
                // TODO: look for cab files and call load
            }
        }
    }
    
    private func populateAssets() {
        for bundle in self.bundles.values {
            for asset in bundle.assets {
                let assetName = asset.name.lowercased()
                if !self.assets.keys.contains(assetName) {
                    self.assets[assetName] = asset
                }
            }
        }
    }
    
    public func getAsset(path: String) -> Asset? {
        guard let urlComponents = URLComponents(string: path) else {
            return nil
        }
        
        if urlComponents.scheme != "archive" {
            print("Error: Unsupported scheme in URL: \(path)")
            return nil
        }
        
        // this might not work here, TODO: proper splitting
        let name = (urlComponents.path as NSString).lastPathComponent
        let archive = (urlComponents.path as NSString).deletingLastPathComponent
        
        if !self.bundles.keys.contains(archive) {
            self.discover(name: archive)
        }
        
        if !self.bundles.keys.contains(archive) {
            print("Error: Unsupported scheme in URL: \(path)")
            return nil
        }
        
        if let bundle = self.bundles[archive] {
            if let asset = bundle.assets.first(where: {$0.name == name}) {
                return asset
            }
        }
        
        print("No such asset: \(name)")
        return nil
    }
    
    
}
