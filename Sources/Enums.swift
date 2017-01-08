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
