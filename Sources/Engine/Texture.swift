//
//  Texture.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 26/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

@objc(Material)
class Material : GameObject {
    
    let globalIlluminationFlags: Int
    let renderQueue: Int
    let shader: ObjectPointer
    let shaderKeywords: [String]
    let savedProperties: [String: Any?]
    
    required init(from dict: [String: Any]) {
        globalIlluminationFlags = dict["m_LightmapFlags"] as! Int
        renderQueue = dict["m_CustomRenderQueue"] as! Int
        shader = dict["m_Shader"] as! ObjectPointer
        shaderKeywords = dict["m_ShaderKeywords"] as! [String]
        // TODO unpack saved properties
        savedProperties = [String: Any?]()
        super.init(from: dict)
    }
}
