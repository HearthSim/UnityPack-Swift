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

        let pathURL = URL(fileURLWithPath: "/Applications/Hearthstone/Data/OSX/cardtextures0.unity3d")
        do {
            let data = try Data(contentsOf: pathURL)
            let unityPack = UnityPack(data: data)
            unityPack.load()
        } catch let error {
            print("\(error)")
        }


    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

