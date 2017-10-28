//
//  Type.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 08/02/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

class TypeTree: CustomStringConvertible {
    var children = [TypeTree]()
    var version: Int32 = 0
    var isArray = false
    var size: Int32 = 0
    var index: Int32 = 0
    var flags: Int32 = 0
    var type = "(null)"
    var name = "(null)"
    var format: UInt32 = 0
    var bufferBytes: UInt32 = 0
    var data = [UInt8]()
    
    public init(format: UInt32) {
        self.format = format
    }
    
    public var description: String {
        return "<\(self.type) \(self.name) (size=\(self.size), index=\(self.index), is_array=\(self.isArray), flags=\(self.flags))>)"
    }
    
    var postAlign: Bool {
        return (self.flags & 0x4000) != 0
    }
    
    func load(buffer: BinaryReader) {
        if self.format == 10 || self.format >= 12 {
            self.loadBlob(buffer: buffer)
        } else {
            self.loadOld(buffer: buffer)
        }
    }
    
    func loadOld(buffer: BinaryReader) {
        self.type = buffer.readString()
        self.name = buffer.readString()
        self.size = buffer.readInt()
        self.index = buffer.readInt()
        self.isArray = buffer.readInt() != 0
        self.version = buffer.readInt()
        self.flags = buffer.readInt()
        
        let numFields = buffer.readInt()
        for _ in 1...numFields {
            let tree = TypeTree(format: self.format)
            tree.load(buffer: buffer)
            self.children.append(tree)
        }
    }
    
    func loadBlob(buffer: BinaryReader) {
        let numNodes: UInt32 = buffer.readUInt()
        self.bufferBytes = buffer.readUInt()
        let nodeData = buffer.readBytes(count: Int(UInt32(24).multipliedReportingOverflow(by: numNodes).0) )
        self.data = buffer.readBytes(count: Int(self.bufferBytes))
        
        var parents = [TypeTree]()
        parents.append(self)
        
        let buf = BinaryReader(data: UPData(withData: Data(bytes: nodeData)))
        buf.endianness = ByteOrder.littleEndian
        
        for _ in 1...numNodes {
            let version = buf.readInt16()
            let depth = buf.readUInt8()
            
            var curr: TypeTree
            if depth == 0 {
                curr = self
            } else {
                while parents.count > Int(depth) {
                    let _ = parents.popLast()
                }
                curr = TypeTree(format: self.format)
                parents[parents.count-1].children.append(curr)
                parents.append(curr)
            }
            
            curr.version = Int32(version)
            curr.isArray = buf.readUInt8() != 0
            curr.type = self.getString(offset: buf.readInt())
            curr.name = self.getString(offset: buf.readInt())
            curr.size = buf.readInt()
            curr.index = Int32(buf.readUInt())
            curr.flags = buf.readInt()
        }
    }
    
    func getString(offset: Int32) -> String {
        var off = offset

        var data: [UInt8]
        if offset < 0 {
            off &= 0x7fffffff
            data = Resources.stringsData
        } else if offset < Int32(self.bufferBytes) {
            data = self.data
        } else {
            return "(null)"
        }
        let subarray = data[Int(off)..<data.count].split(separator: 0)[0]
        if let string = String(bytes: subarray, encoding: .utf8) {
            return string.characters.filter { $0 != "\0" }
                .map { String($0) }
                .joined()
        }
        
        fatalError("Cannot convert data to string")
    }
}

class TypeMetadata {
    
    fileprivate static var instance: TypeMetadata?
    
    static func defaultTypeWith(asset: Asset) -> TypeMetadata {
        if let defaultInstance = instance {
            return defaultInstance
        }
        
        instance = TypeMetadata(asset: asset)
        instance?.load(buffer: BinaryReader(data: UPData(withData: Data(bytes: Resources.structsData))), format: 15)
        return instance!
    }
    
    weak var asset: Asset?
	var classIds = [Int32]()
    var typeTrees = [Int: TypeTree]()
    var hashes = [Int: [UInt8]]()
    var generatorVersion = ""
    var targetPlatform: RuntimePlatform = .OSXEditor
    
    public init(asset: Asset?) {
        self.asset = asset
    }
    
    func load(buffer: BinaryReader, format: UInt32 = 0) {
        var format = format
        if format == 0 {
            if let asset = self.asset {
                format = asset.format
            }
        }
        
        self.generatorVersion = buffer.readString()
        self.targetPlatform = GetRuntimePlatform(value: buffer.readUInt())
        
        if format >= 13 {
            
            let hastTypeTrees = buffer.readBool()
            let numTypes = buffer.readInt()
            
            for _ in 1...numTypes {
                var classId = buffer.readInt()
				
				if format >= 17 {
					let _ = buffer.readBytes(count: 1)
					let scriptId = buffer.readInt16()
					if classId == 114 {
						if scriptId >= 0 {
							/* make up a fake negative class_id to work like the
							old system.  class_id of -1 is taken to mean that
							the MonoBehaviour base class was serialized; that
							shouldn't happen, but it's easy to account for. */
							classId = Int32(-2 - scriptId)
						} else {
							classId = -1
						}
					}
				}
				self.classIds.append(classId)
				
                var hash: [UInt8]
                if classId < 0 {
                    hash = buffer.readBytes(count: 0x20)
                } else {
                    hash = buffer.readBytes(count: 0x10)
                }
                
                self.hashes[Int(classId)] = hash
                
                if hastTypeTrees {
                    let tree = TypeTree(format: format)
                    tree.load(buffer: buffer)
                    self.typeTrees[Int(classId)] = tree
                }
            }

        } else {
            let numFields = buffer.readInt()
            for _ in 1...numFields {
                let classId = buffer.readInt()
                let tree = TypeTree(format: format)
                tree.load(buffer: buffer)
                self.typeTrees[Int(classId)] = tree
            }
        }
    }
}































