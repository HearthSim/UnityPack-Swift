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
        // TODO: load strings.dat
        strings = [UInt8]()
        
        // TODO: load structs.dat
        structs = [UInt8]()
    }
    
    public static var stringsData: [UInt8] {
        return instance.strings
    }
    
    public static var structsData: [UInt8] {
        return instance.structs
    }
    
}
