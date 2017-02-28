//
//  Object.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 07/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

func loadObject(type: TypeTree, dict: [String: Any?]) -> Any? {
    let clsname = type.type
    
    if let classType = NSClassFromString(clsname) as? EngineObject.Type {
        let obj = classType.init(from: dict)
        return obj
    } else {
        // print("Missing type implementation for \(clsname)")
    }
    
    return dict
}

public class ObjectInfo: CustomStringConvertible {
    
    let asset: Asset
    var typeId: Int = 0
    var pathId: Int64 = 0
    var dataOffset: UInt32 = 0
    var size: UInt32 = 0
    var classId: Int16 = 0
    var isDestroyed = false
    var unk0: Int16 = 0
    var unk1: UInt8 = 0
    
    public init(asset: Asset) {
        self.asset = asset
    }
    
    public var description: String {
        return "<\(self.type) \(self.classId)>)"
    }
    
    var type: String {
        if self.typeId > 0 {
            return UnityClass.getUnityClass(fromType: self.typeId)
        } else if self.asset.typenames[self.typeId] == nil {
            let rawdata = self.read()
            var typename = ""
            if let dict = rawdata as? [String: Any?] {
                
                if let script = dict["m_Script"] {
                    if let pointer = script as? ObjectPointer {
                        if let resolved = pointer.resolve() {
                            if let ressdict = resolved as? [String: Any?] {
                                if let name = ressdict["m_ClassName"] {
                                    typename = name as! String
                                } else {
                                    fatalError("Resolved object pointer has no name field")
                                }
                            } else {
                                fatalError("Resolved object pointer is not a dictionary")
                            }
                        } else {
                            // type not implemented, capture type name in PPtr<...>
                            typename = pointer.type.type
                            let startIndex =  typename.index(typename.startIndex, offsetBy: 5)
                            let endIndex = typename.index(typename.startIndex, offsetBy: -1)
                            typename = typename[startIndex ... endIndex]
                        }
                    } else {
                        fatalError("Object type \(script) is not ObjectPointer")
                    }
                } else {
                    fatalError("Object type \(dict) is not dictionary type")
                }
            } else {
                typename = (self.asset.tree.typeTrees[-150]?.type)!
            }
            self.asset.typenames[self.typeId] = typename
        }
        return self.asset.typenames[self.typeId]!
    }
    
    var typeTree: TypeTree? {
        if self.typeId < 0 {
            let typeTrees = self.asset.tree.typeTrees
            if let result = typeTrees[Int(self.typeId)] {
                return result
            }
            
            if let result = typeTrees[Int(self.classId)] {
                return result
            }
            return TypeMetadata.defaultTypeWith(asset: self.asset).typeTrees[Int(self.classId)]
        }
        return self.asset.types[Int(self.typeId)]
    }
    
    func load(buffer: BinaryReader) {
        self.pathId = self.readId(buffer: buffer)
        self.dataOffset = buffer.readUInt() + self.asset.dataOffset
        self.size = buffer.readUInt()
        self.typeId = Int(buffer.readInt())
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
            buf.seek(count: Int32(self.asset._buf_ofs + Int(self.dataOffset)) )
            if let typeTree = self.typeTree {
                return self.readValue(type: typeTree, buffer: buf)
            }
        }
        return nil
    }
    
    func readValue(type: TypeTree, buffer: BinaryReader) -> Any? {
        var align = false
        let t = type.type
        var firstChild = type.children.count > 0 ? type.children[0] : TypeTree(format: self.asset.format)
        
        var result: Any? = nil
        
        if t == "bool" {
            result = buffer.readBool()
        } else if t == "UInt8" {
            result =  buffer.readUInt8()
        } else if t == "SInt16" {
            result =  buffer.readInt16()
        } else if t == "UInt16" {
            result =  buffer.readInt16()
        } else if t == "SInt64" {
            result =  buffer.readInt64()
        } else if t == "UInt64" {
            result =  buffer.readInt64()
        } else if t == "UInt32" || t == "unsigned int" {
            result =  buffer.readUInt()
        } else if t == "SInt32" || t == "int" {
            result =  buffer.readInt()
        } else if t == "float" {
            result =  buffer.readFloat()
        } else if t == "string" {
            let size = buffer.readUInt()
            result = buffer.readString(size: Int(size))
            align = type.children[0].postAlign
        } else {
            if type.isArray {
                firstChild = type
            }
            
            if t.contains("PPtr<") {
                result = ObjectPointer(type: type, asset: self.asset)
                (result as! ObjectPointer).load(buffer: buffer)
                if !(result as! ObjectPointer).isValid() {
                    result = nil
                }
            } else if firstChild.isArray {
                align = firstChild.postAlign
                let size = buffer.readUInt()
                let arrayType = firstChild.children[1]
                if arrayType.type == "char" || arrayType.type == "UInt8" {
                    result = buffer.readBytes(count: Int(size))
                } else {
                    var arr = [Any?]()
                    for _ in 0..<size {
                        arr.append(self.readValue(type: arrayType, buffer: buffer))
                    }
                    result = arr
                }
            } else if t == "pair" {
                assert(type.children.count == 2, "Type pair needs exactly 2 elements not \(type.children.count)")
                let first = self.readValue(type: type.children[0], buffer: buffer)
                let second = self.readValue(type: type.children[1], buffer: buffer)
                result = (first: first, second: second)
            } else {
                var map = [String:Any?]()
                
                for child in type.children {
                    map[child.name] = self.readValue(type: child, buffer: buffer)
                }
                
                result = loadObject(type: type, dict: map)
                if t == "StreamedResource" {
                    if self.asset.bundle != nil {
                        //TODO: streamable
                        //(result as! StreamedResource).asset = self.asset.getAsset(result.source)
                    } else {
                        print("StreamedResource not available without bundle")
                        //(result as! StreamedResource).asset = nil
                    }
                }
            }
            
    
        }
        
        if align || type.postAlign {
            buffer.align()
        }
        
        return result
    }
}

public class ObjectPointer: CustomStringConvertible {
    
    let type: TypeTree
    let source_asset: Asset
    var fileId: Int32 = 0
    var pathId: Int64 = 0
    
    init(type: TypeTree, asset: Asset) {
        self.type = type
        self.source_asset = asset
    }
    
    public var description: String {
        return "\(String(describing: ObjectPointer.self))(file_id=\(self.fileId), path_id=\(self.pathId)"
    }
    
    public func isValid() -> Bool {
        return !(self.fileId == 0 && self.pathId == 0)
    }
    
    var asset: Asset? { // Asset or AssetRef
        if Int32(self.source_asset.assetRefs.count) > self.fileId {
            let ret = self.source_asset.assetRefs[Int(self.fileId)]
            if let assetRef = ret as? AssetRef {
                return assetRef.resolve()
            }
            return ret as? Asset
        }
        return nil
    }
    
    var object: ObjectInfo? {
        if let assetRef = self.asset {
            return assetRef.objects[Int64(self.pathId)]
        }
        return nil
    }
    
    func load(buffer: BinaryReader) {
        self.fileId = buffer.readInt()
        self.pathId = self.source_asset.readId(buffer: buffer)
    }
    
    func resolve() -> Any? {
        if let obj = self.object {
            return obj.read()
        }
        return nil
    }
}
