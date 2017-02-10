//
//  Object.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 07/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class ObjectInfo {
    
    let asset: Asset
    var typeId: UInt32 = 0
    var pathId: Int64
    var dataOffset: UInt32
    var size: UInt32
    var classId: Int16
    var isDestroyed = false
    var unk0: Int16
    var unk1: UInt8
    
    public init(asset: Asset) {
        self.asset = asset
    }
    
    public var description: String {
        return "<\(self.type) \(self.classId)>)"
    }
    
    var type: String {
        if self.typeId > 0 {
            return UnityClass.getUnityClass(fromType: self.typeId)
        } else if !self.asset.typenames.keys.contains(self.typeId) {
            //let script = self.read()["m_Script"]
            // TODO: type resolve
            // ..
            // self.asset.typenames[self.typeId] = typename
        }
        return self.asset.typenames[self.typeId]
    }
    
    var typeTree: String {
        if self.typeId < 0 {
            let typeTrees = self.asset.tree.typeTrees
            if let result = typeTrees[self.typeId] {
                return result
            }
            
            if let result = typeTrees[self.classId] {
                return result
            }
            return TypeMetadata.default(self.asset).typeTrees[self.classId]
        }
        return self.asset.types[self.typeId]
    }
    
    func load(buffer: BinaryReader) {
        self.pathId = self.readId(buffer: buffer)
        self.dataOffset = buffer.readUInt() + self.asset.dataOffset
        self.size = buffer.readUInt()
        self.typeId = buffer.readUInt()
        self.classId = buffer.readInt16()
        
        if self.asset.format <= 10 {
            self.isDestroyed = buffer.readInt16() != 0
        } else if self.asset.format >= 11 {
            self.unk0 = buffer.readInt16()
            
            if self.asset.format >= 15 {
                self.unk1 = buffer.readUInt8()
            }
        }
    }
    
    func readId(buffer: BinaryReader) -> Int64 {
        if self.asset.longObjectIds {
            return buffer.readInt64()
        }
        return self.asset.readId(buffer: buffer)
    }
    
    func read() -> Any? {
        if let buf = self.asset._buf {
            buf.seek(count: (self.asset._buf_ofs + Int(self.dataOffset)) )
            return self.readValue(type: self.typeTree, buffer: buf)
        }
        return nil
    }
    
    func readValue(type: TypeTree, buffer: BinaryReader) -> Any? {
        let align = false
        let t = type.type
        let firstChild = type.children ? type.children[0] : TypeTree(self.asset.format)
        
        if t == "bool" {
            //return buffer.readBool()
        }
        
        // TODO readValue
    }
}
























