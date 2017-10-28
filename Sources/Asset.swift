//
//  Asset.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 05/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

public class Asset: CustomStringConvertible {
    public var name: String = ""
    var loaded = false
    var longObjectIds = false
    weak var bundle: AssetBundle?
    weak var environment: UnityEnvironment?
    
    var _buf: BinaryReader?
    var _buf_ofs: Int = 0
    var header_size: UInt32 = 0
    var base_path: String?
    
    var metadataSize: UInt32 = 0
    var fileSize: UInt32 = 0
    var format: UInt32 = 0
    var dataOffset: UInt32 = 0
    var endianness: UInt32 = 0
    
    var tree = TypeMetadata(asset: nil)
    lazy var assetRefs: [Any?] = {
        var aRef = [Any?]()
        aRef.append(self)
        return aRef;
    }()
    
    var _objects = [Int64: ObjectInfo]()
    var typenames = [Int : String]()
    var types = [Int: TypeTree]()
    var adds = [(v1: Int64, v2: Int32)]()
    
    
    public init(fromBundle bundle: AssetBundle, buf: Readable) {
        
        self.bundle = bundle
        self.environment = bundle.environment
        //let offset: Int = buf.tell
        self._buf = BinaryReader(data: buf)
        self.tree = TypeMetadata(asset: self)
        
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
            header_size = bundle.rawDescriptor.assetHeaderSize
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
    
    public init?(fromFile filePath: String) {
        fatalError("Error: Asset::fromFile is not yet implemented")
        /*self.name = (filePath as NSString).lastPathComponent
        self._buf_ofs = 0
        
        // TODO: fileHandle bla bla
        // ret._buf = BinaryReader(fileHandle)
        self.base_path = filePath //(full)
        if let path = self.base_path {
            self.environment = UnityEnvironment(base_path: path)
        }
        */
    }
    
    public func getAsset(path: String) -> Asset? {
        if let env = self.environment {
            if path.contains(":") {
                return env.getAsset(path: path)
            }
            return env.getAsset(fileName: path)
        }
        return nil
    }
    
    public var description: String {
        return "<\(String(describing: Asset.self)) \(self.name)>)"
    }
    
    
    public var objects: [Int64: ObjectInfo] {
        if !self.loaded {
            do {
                try self.load()
            } catch let error {
                print("\(error)")
            }
        }
        return self._objects
    }
    
    var isResource: Bool {
        return (self.name as NSString).lastPathComponent == ("resource")
    }
    
    
    private func load() throws {
        if self.isResource {
            self.loaded = true
            return
        }
        
        if let buf = self._buf {
            
            buf.seek(count: Int32(self._buf_ofs))
			buf.endianness = .bigEndian
			
            self.metadataSize = buf.readUInt()
            self.fileSize = buf.readUInt()
            self.format = buf.readUInt()
            self.dataOffset = buf.readUInt()
            
            if self.format >= 9 {
                self.endianness = buf.readUInt()
                if self.endianness == 0 {
                    buf.endianness = .littleEndian;
                }
            }
            
            self.tree.load(buffer: buf)
            
            if ((self.format >= 7) && (self.format <= 13)) {
                self.longObjectIds = buf.readUInt() != 0
            }
            
            let num_objects = buf.readUInt();
            
            for _ in 1...num_objects {
                if self.format >= 14 {
                    buf.align()
                }
                
                let obj = ObjectInfo(asset: self)
                obj.load(buffer: buf)
                self.registerObject(obj: obj)
                // accessing object's properties here is a bad idea as they will refer back to this (unloaded) asset
                //print("Found object \(obj)")
            }
            
            if self.format >= 11 {
                let numAdds = buf.readUInt()
                for _ in 0 ..< numAdds {
                    if self.format >= 14 {
                        buf.align()
                    }
                    let id = self.readId(buffer: buf)
                    self.adds.append((id, buf.readInt()))
                }
            }
            
            if self.format >= 6 {
                let numRefs = buf.readUInt()
                for _ in 0 ..< numRefs {
                    let ref = AssetRef(source: self)
                    ref.load(buffer: buf)
                    self.assetRefs.append(ref)
                }
            }
            
            let unkString = buf.readString()
            precondition(unkString == "", "Error while loading Asset, ending string is \(unkString)")
  
            self.loaded = true
        }
    }
    
    func readId(buffer: BinaryReader) -> Int64 {
        if self.format >= 14 {
            return buffer.readInt64()
        }
        return Int64(buffer.readInt())
    }
    
    func registerObject(obj: ObjectInfo) {
        
        if let oType = self.tree.typeTrees[Int(obj.typeId)] {
            self.types[Int(obj.typeId)] = oType
        } else if self.types[Int(obj.typeId)] == nil {
            let trees = TypeMetadata.defaultTypeWith(asset: self).typeTrees
            if let oType = trees[Int(obj.classId)] {
                self.types[Int(obj.typeId)] = oType
            } else {
                print("\(obj.classId) absent from structs.dat")
                self.types[Int(obj.typeId)] = nil
            }
        }
        
        if self._objects[obj.pathId] != nil {
            print("Duplicate asset object: \(obj) (path_id=\(obj.pathId))")
        }
        
        self._objects[obj.pathId] = obj
    }
    
    func pretty() {
        // TODO: Asset::pretty
        fatalError("Asset::pretty is not yet implemented")
    }
}

class AssetRef: CustomStringConvertible {
    
    let source: Asset
    var assetPath: String = ""
    var filePath: String = ""
    var guid: NSUUID?
    var type: Int32 = 0
    var asset: Asset?
    
    public init(source: Asset) {
        self.source = source
    }
    
    public var description: String {
        return "<\(String(describing: AssetRef.self)) asset_path=\(self.assetPath), guid=\(String(describing: self.guid)), type=\(self.type), file_path=\(self.filePath)>)"
    }
    
    func load(buffer: BinaryReader) {
        self.assetPath = buffer.readString()
        let uuidBytes = buffer.readBytes(count: 16)
        
        self.guid = NSUUID(uuidBytes: uuidBytes)
        
        self.type = buffer.readInt()
        self.filePath = buffer.readString()
        self.asset = nil
    }
    
    func resolve() -> Asset? {
        return self.source.getAsset(path: self.filePath)
    }
}
