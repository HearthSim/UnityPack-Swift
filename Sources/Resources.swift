//
//  Resources.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 08/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class UnityClass {
    
    static let instance = UnityClass()
    
    private var UNITYCLASSES = [String : String]()
    
    private init() {
        // TODO: load Unityclasses from JSON
        // json load classes.json
    }
    
    public static func getUnityClass(fromType: UInt32) -> String {
        let typeStr = String(fromType)
        if let classname = instance.UNITYCLASSES[typeStr] {
            return classname
        }
        return "<Unknown \(typeStr)>"
    }
    
}

class Resources {
    
    static let instance = Resources()
    
    private let strings: [UInt8]
    private let structs: [UInt8]
    
    private init() {
        // load strings.dat
        let bundle = Bundle(for: type(of: self))
        if let stringsPath = bundle.path(forResource: "strings", ofType: "dat", inDirectory: "Resources") {
            if let stringsData = NSData(contentsOfFile: stringsPath) {
                var buffer = [UInt8](repeating: 0, count: stringsData.length)
                stringsData.getBytes(&buffer, length: stringsData.length)
                strings = buffer
            } else {
                fatalError("Cannot load strings.dat")
            }
        } else {
            fatalError("Cannot load strings.dat")
        }
                
        // load structs.dat
        if let structsPath = bundle.path(forResource: "structs", ofType: "dat", inDirectory: "Resources") {
            if let structsData = NSData(contentsOfFile: structsPath) {
                var buffer = [UInt8](repeating: 0, count: structsData.length)
                structsData.getBytes(&buffer, length: structsData.length)
                structs = buffer
            } else {
                fatalError("Cannot load structs.dat")
            }
        } else {
            fatalError("Cannot load structs.dat")
        }
    }
    
    public static var stringsData: [UInt8] {
        return instance.strings
    }
    
    public static var structsData: [UInt8] {
        return instance.structs
    }
    
}
