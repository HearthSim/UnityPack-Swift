//
//  main.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 23/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import UnityPack

do {
    let files = ["cardtextures0", "cards0", "cardxml0"]
    var allCards = [[(path: String, tile: Any?)]]()
    var allTtextures = [[String: ObjectPointer]]()
    
    for file in files {
        let filePath = "/Applications/Hearthstone/Data/OSX/" + file + ".unity3d"
        
        if let bundle = try UnityPack.load(withFilePath: filePath) {
            
            for asset in bundle.assets {
                print("Parsing \(asset.name)")
                let (cards, textures) = UnityPack.extractCardsAndTextures(asset: asset)
                allCards.append(cards)
                allTtextures.append(textures)
            }
        }
    }

} catch let error {
    print("\(error)")
}
