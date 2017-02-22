//
//  AppDelegate.swift
//  UnityPackExample
//
//  Created by Benjamin Michotte on 3/01/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Cocoa
import UnityPack

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {

        do {
            let files = [/*"cardtextures0",*/ "cards0"/*, "cardxml0"*/]
            //var cards = []
            //var textures = []
            
            for file in files {
                let filePath = "/Applications/Hearthstone/Data/OSX/" + file + ".unity3d"
                
                if let bundle = try UnityPack.load(withFilePath: filePath) {
                    
                    for asset in bundle.assets {
                        print("Parsing \(asset.name)")
                        //handleAsset(asset, textures, cards, filter_ids)
                        
                        for obj in asset.objects.values {
                            print("object: \(obj)")
                        }
                        
                    }
                }
                
                
            }
            
            
            
        } catch let error {
            print("\(error)")
        }

        NSApplication.shared().terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

