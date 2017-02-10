//
//  Enums.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 05/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

enum FileSignature: String {
    case SIGNATURE_FS = "UnityFS"
    case SIGNATURE_WEB = "UnityWeb"
    case SIGNATURE_RAW = "UnityRaw"
}

enum CompressionType: UInt32 {
    case NONE = 0
    case LZMA = 1
    case LZ4 = 2
    case LZ4HC = 3
    case LZHAM = 4
    // not in unity defined
    case LZFSE = 10
    case ZLIB = 11
}

enum RuntimePlatform: UInt32 {
    case OSXEditor
    case OSXPlayer
    case WindowsPlayer
    case OSXWebPlayer
    case OSXDashboardPlayer
    case WindowsWebPlayer
    case WindowsEditor
    case IPhonePlayer
    case PS3
    case XBOX360
    case Android
    case NaCl
    case LinuxPlayer
    case FlashPlayer
    case WebGLPlayer
    case MetroPlayerX86
    case WSAPlayerX86
    case MetroPlayerX64
    case WSAPlayerX64
    case MetroPlayerARM
    case WSAPlayerARM
    case WP8Player
    case BB10Player
    case BlackBerryPlayer
    case TizenPlayer
    case PSP2
    case PS4
    case PSM
    case PSMPlayer
    case XboxOne
    case SamsungTVPlayer
}

func GetRuntimePlatform(value: UInt32) -> RuntimePlatform {
    switch value {
    case 0:
        return .OSXEditor
    case 1:
        return .OSXPlayer
    case 2:
        return .WindowsPlayer
    case 3:
        return .OSXWebPlayer
    case 4:
        return .OSXDashboardPlayer
    case 5:
        return .WindowsWebPlayer
    case 7:
        return .WindowsEditor
    case 8:
        return .IPhonePlayer
    case 9:
        return .PS3
    case 10:
        return .XBOX360
    case 11:
        return .Android
    case 12:
        return .NaCl
    case 13:
        return .LinuxPlayer
    case 15:
        return .FlashPlayer
    case 17:
        return .WebGLPlayer
    case 18:
        return .MetroPlayerX86
    case 19:
        return .MetroPlayerX64
    case 20:
        return .MetroPlayerARM
    case 21:
        return .WP8Player
    case 22:
        return .BB10Player
    case 23:
        return .TizenPlayer
    case 24:
        return .PSP2
    case 25:
        return .PS4
    case 26:
        return .PSM
    case 27:
        return .XboxOne
    case 28:
        return .SamsungTVPlayer
        
    default:
        return .OSXEditor
    }
}
