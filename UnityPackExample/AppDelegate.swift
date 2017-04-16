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
    @IBOutlet weak var imageView: NSImageView!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {

        guard let unitypack = UnityPack(with: "/Applications/Hearthstone") else {
            print("Error initializing UnityPack")
            exit(-1)
        }
        
        // leper gnome
        let (image, tile) = unitypack.getTexture(cardid: "CS2_031")
        if let image = image, let _ = tile { // CS2_031 , EX1_029
            imageView.image = image
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

