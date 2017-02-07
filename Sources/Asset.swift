//
//  Asset.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 05/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

public class Asset {
    var name: String = ""
    var loaded = false
    var long_object_ids = false
    var bundle: AssetBundle
    var environment: UnityEnvironment
    
    var _buf: BinaryReader
    var _buf_ofs: Int = 0
    var header_size: UInt32 = 0
    
    //public init() {
        //self._buf_ofs = None
        //self._objects = {}
        //self.adds = []
        //self.asset_refs = [self]
        //self.types = {}
        //self.typenames = {}
        //self.bundle = None
        //self.tree = TypeMetadata(self)
    //}
    
    public init(from_bundle bundle: AssetBundle, buf: Readable) {
        
        self.bundle = bundle
        self.environment = bundle.environment
        let offset: Int = buf.tell
        self._buf = BinaryReader(data: buf)
        
        if bundle.isUnityFS {
            self._buf_ofs = buf.tell
            return
        }
        
        if !bundle.compressed {
            let reader = BinaryReader(data: buf)
            self.name = reader.readString()
            header_size = reader.readUInt()
            let _ = reader.readUInt()  // size
        } else {
            header_size = bundle.asset_header_size
        }
        
        // FIXME: this offset needs to be explored more (not implemented yet)
        /*let ofs = buf.tell
        if bundle.compressed {
            let d = Data(bytes: buf.readAll)
            dec = lzma.LZMADecompressor()
            data = dec.decompress(buf.read())
            self._buf = BinaryReader(BytesIO(data[header_size:]), endian=">")
            self._buf_ofs = 0
            buf.seek(ofs)
        } else {
            self._buf_ofs = offset + Int(header_size) - 4
            if self.is_resource {
                self._buf_ofs -= len(ret.name)
            }
        }*/
        
    }
}
