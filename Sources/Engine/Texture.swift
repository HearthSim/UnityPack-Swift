//
//  Texture.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 26/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

@objc(Material)
class Material : EngineObject {
    
    let globalIlluminationFlags: UInt32
    let renderQueue: Int32
    let shader: ObjectPointer
    let shaderKeywords: String
    let savedProperties: [String: [String: Any?]]
    
    required init(from dict: [String: Any?]) {
        globalIlluminationFlags = dict["m_LightmapFlags"] as! UInt32
        renderQueue = dict["m_CustomRenderQueue"] as! Int32
        shader = dict["m_Shader"] as! ObjectPointer
        shaderKeywords = dict["m_ShaderKeywords"] as! String
        // unpack saved properties
        var properties = [String: [String: Any?]]()
        
        if let prop = dict["m_SavedProperties"] as? [String: Any?] {
            for (basekey, value) in prop {
                var elements = [String: Any?]()
                for v in (value as! [(Any?, Any?)]) {
                    let key = ((v.0 as! [String: String])["name"])! as String
                    elements[key] = v.1
                }
                
                properties[basekey] = elements
            }
        }
        
        savedProperties = properties
        
        super.init(from: dict)
    }
}
