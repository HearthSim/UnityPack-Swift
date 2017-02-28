//
//  Texture.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 26/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import AppKit

enum TextureFormat: Int32 {
    case Alpha8 = 1
    case ARGB4444 = 2
    case RGB24 = 3
    case RGBA32 = 4
    case ARGB32 = 5
    case RGB565 = 7

    // Direct3D
    case DXT1 = 10
    case DXT5 = 12

    case RGBA4444 = 13
    case BGRA32 = 14

    case DXT1Crunched = 28
    case DXT5Crunched = 29

    // PowerVR
    case PVRTC_RGB2 = 30
    static let PVRTC_2BPP_RGB = TextureFormat.PVRTC_RGB2
    case PVRTC_RGBA2 = 31
    static let PVRTC_2BPP_RGBA = TextureFormat.PVRTC_RGBA2
    case PVRTC_RGB4 = 32
    static let PVRTC_4BPP_RGB = TextureFormat.PVRTC_RGB4
    case PVRTC_RGBA4 = 33
    static let PVRTC_4BPP_RGBA = TextureFormat.PVRTC_RGBA4

    // Ericsson (Android)
    case ETC_RGB4 = 34
    case ATC_RGB4 = 35
    case ATC_RGBA8 = 36

    // Adobe ATF
    case ATF_RGB_DXT1 = 38
    case ATF_RGBA_JPG = 39
    case ATF_RGB_JPG = 40

    // Ericsson
    case EAC_R = 41
    case EAC_R_SIGNED = 42
    case EAC_RG = 43
    case EAC_RG_SIGNED = 44
    case ETC2_RGB = 45
    case ETC2_RGBA1 = 46
    case ETC2_RGBA8 = 47

    // OpenGL / GLES
    case ASTC_RGB_4x4 = 48
    case ASTC_RGB_5x5 = 49
    case ASTC_RGB_6x6 = 50
    case ASTC_RGB_8x8 = 51
    case ASTC_RGB_10x10 = 52
    case ASTC_RGB_12x12 = 53
    case ASTC_RGBA_4x4 = 54
    case ASTC_RGBA_5x5 = 55
    case ASTC_RGBA_6x6 = 56
    case ASTC_RGBA_8x8 = 57
    case ASTC_RGBA_10x10 = 58
    case ASTC_RGBA_12x12 = 59
    
    var pixelFormat: String {
        if self == TextureFormat.RGB24 {
            return "RGB"
        }
        else if self == TextureFormat.ARGB32 {
            return "ARGB"
        }
        else if self == TextureFormat.RGB565 {
            return "RGB;16"
        }
        else if self == TextureFormat.Alpha8 {
            return "A"
        }
        else if self == TextureFormat.RGBA4444 {
            return "RGBA;4B"
        }
        else if self == TextureFormat.ARGB4444 {
            return "RGBA;4B"
        }
        return "RGBA"
    }
}


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

@objc(Texture)
class Texture : EngineObject {
    let height: Int32
    let width: Int32
    
    required init(from dict: [String: Any?]) {
        height = dict["m_Height"] as! Int32
        width = dict["m_Width"] as! Int32
        
        super.init(from: dict)
    }
}

@objc(Texture2D)
class Texture2D : Texture {
    let data: Data
    let lightmapFormat: Int32
    let textureSettings: [String: Any?]
    let colorSpace: Int32
    let isReadable: Bool
    let readAllowed: Bool
    let format: TextureFormat
    let textureDimension: Int32
    let mipmap: Int32
    let completeImageSize: Int32
    let streamData: [String: Any?]
    
    required init(from dict: [String: Any?]) {
        data = Data(bytes: dict["image data"] as! [UInt8])
        lightmapFormat = dict["m_LightmapFormat"] as! Int32
        textureSettings = dict["m_TextureSettings"] as! [String: Any?]
        colorSpace = dict["m_ColorSpace"] as! Int32
        isReadable = dict["m_IsReadable"] as! Bool
        readAllowed = dict["m_ReadAllowed"] as! Bool
        format = TextureFormat(rawValue: dict["m_TextureFormat"] as! Int32)!
        textureDimension = dict["m_TextureDimension"] as! Int32
        mipmap = dict["m_MipCount"] as! Int32
        completeImageSize = dict["m_CompleteImageSize"] as! Int32
        streamData = dict["m_StreamData"] as! [String: Any?] // or false
        
        super.init(from: dict)
    }
    
    var image: NSImage? {
        return NSImage(data:data)
    }
}
