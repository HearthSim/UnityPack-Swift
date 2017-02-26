//
//  EngineObjects.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 23/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

@objc(EngineObject)
class EngineObject : NSObject {
    
    let name: String
    
    required init(from dict: [String: Any]) {
        if let n = dict["m_Name"] {
            name = n as! String
        } else {
            name = ""
        }
        super.init()
    }
}

@objc(GameObject)
class GameObject : EngineObject {
    
    let active: Bool
    let component: [(Int32, ObjectPointer)]
    let layer: Int
    let tag: Int16
    
    required init(from dict: [String: Any]) {
        active = dict["m_IsActive"] as! Bool
        self.component = (dict["m_Component"] as! [(Any?, Any?)]).map { ($0.0 as! Int32, $0.1 as! ObjectPointer) }
        layer = Int(dict["m_Layer"] as! UInt32)
        tag = dict["m_Tag"] as! Int16
        super.init(from: dict)
    }
}
