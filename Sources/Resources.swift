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
    
    private var unityClasses: [String : String]
    
    private init() {
        // load Unityclasses from JSON
        let bundle = Bundle(for: type(of: self))
        if let classesPath = bundle.path(forResource: "classes", ofType: "json", inDirectory: "Resources") {
            if let classesData = NSData(contentsOfFile: classesPath) {
                do {
                    if let dictionaryOK = try JSONSerialization.jsonObject(with: Data(referencing: classesData), options: []) as? [String: String] {
                        unityClasses = dictionaryOK
                        return
                    }
                } catch {
                    fatalError("Cannot parse classes.json")
                }
            } else {
                fatalError("Cannot load classes.json")
            }
        } else {
            fatalError("Cannot load classes.json")
        }
        unityClasses = [String : String]()
    }
    
    public static func getUnityClass(fromType: Int) -> String {
        let typeStr = String(fromType)
        if let classname = instance.unityClasses[typeStr] {
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
