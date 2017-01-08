//
//  AssetBundle.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 05/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

public class AssetBundle {
    public var path: String?
    let environment: UnityEnvironment
    
    public var assets = [Asset]()
    public var name: String?
    
    private var signature: FileSignature?
    private var formatVersion: Int32 = 0
    private var unityVersion = ""
    private var generatorVersion = ""
    
    private var fsFileSize: Int64 = 0
    private var ciblockSize: UInt32 = 0
    private var uiblockSize: UInt32 = 0
    
    var asset_header_size: UInt32 = 0 // only when raw
    
    
    init(_ environment: UnityEnvironment) {
        self.environment = environment;
    }
    
    public var description: String {
        if let n = self.name {
            return "<\(String(describing: AssetBundle.self)) \(n)>)"
        }
        return "<\(String(describing: AssetBundle.self))>)"
    }
    
    public var isUnityFS: Bool {
        if let sig = self.signature {
            return sig == .SIGNATURE_FS
        }
        return false
    }
    
    public var compressed: Bool {
        if let sig = self.signature {
            return sig == .SIGNATURE_WEB
        }
        return false
    }
    
    public func load(_ filePath: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        
        self.path = (filePath as NSString).lastPathComponent
        
        let buf = BinaryReader(data: UPData(withData:data))
        
        self.signature = FileSignature(rawValue: buf.readString())
        self.formatVersion = buf.readInt()
        self.unityVersion = buf.readString()
        self.generatorVersion = buf.readString()

        if isUnityFS {
            try loadUnityFs(buf: buf)
        } else {
            loadRaw(buf: buf)
        }
    }
    
    private func loadUnityFs(buf: BinaryReader) throws {
        
        self.fsFileSize = buf.readInt64()
        self.ciblockSize = buf.readUInt()
        self.uiblockSize = buf.readUInt()
        
        let flags = buf.readUInt()
        guard let compression = CompressionType(rawValue: flags & 0x3F) else { return }
        
        guard let data = try self.readCompressedData(buf: buf, compression: compression, blockSize: uiblockSize) else { return }
        
        let blk = BinaryReader(data: UPData(withData: data))
        let guid = blk.readBytes(count: 16)
        let num_blocks = blk.readInt()
        
        var blocks = [ArchiveBlockInfo]()
        
        for _ in 1 ... num_blocks {
            let busize = blk.readInt()
            let bcsize = blk.readInt()
            let bflags = blk.readInt16()
            blocks.append(ArchiveBlockInfo(uSize: busize, cSize: bcsize, flags: bflags))
        }
        
        let num_nodes = blk.readInt()
        
        struct AssetDataInfo {
            var ofs: Int
            var size: Int
            var status: Int32
            var name: String
            init(ofs: Int, size: Int, status: Int32, name: String) {
                self.ofs = ofs
                self.size = size
                self.status = status
                self.name = name
            }
        }
        
        var nodes = [AssetDataInfo]()
        
        for _ in 1 ... num_nodes {
            let ofs = blk.readInt64()
            let size = blk.readInt64()
            let status = blk.readInt()
            let name = blk.readString()
            nodes.append(AssetDataInfo(ofs:Int(ofs), size:Int(size), status:status, name:name))
        }
        
        let storage = ArchiveBlockStorage(blocks: blocks, stream: buf)
        for info in nodes {
            storage.seek(count: info.ofs)
            var asset = Asset(from_bundle: self, buf: storage)
            asset.name = info.name
            self.assets.append(asset)
        }
        
        // Hacky
        self.name = self.assets[0].name
    }
    
    private func loadRaw(buf: BinaryReader) {
        // TODO: loading raw data
    }
    
    private func readCompressedData(buf: BinaryReader, compression: CompressionType, blockSize: UInt32) throws -> Data? {
        let nsdata = NSData(data: Data(bytes: BinaryReader.toByteArray(blockSize) + buf.readBytes(count: Int(ciblockSize) )))
        
        //let array = [UInt8](dt)
        //print("compressed data: \(array)");
        //print("compressed data: \(array.map { String($0, radix: 16, uppercase: false) })");
        
        if compression == .none {
            return Data(referencing: nsdata)
        }
        
        if compression == .LZ4 || compression == .LZ4HC {
            return nsdata.decompressLZ4();
        }
        
        return nil
    }
}

class ArchiveBlockInfo {
    
    let uncompressed_size: Int32
    let compressed_size: Int32
    let flags: Int16
    
    init(uSize: Int32, cSize: Int32, flags: Int16) {
        self.uncompressed_size = uSize
        self.compressed_size = cSize
        self.flags = flags
    }
    
    var compressed: Bool {
        return self.compression_type != CompressionType.NONE
    }
    
    var compression_type: CompressionType {
        if let ct = CompressionType(rawValue: UInt32(self.flags & 0x3f)) {
            return ct
        }
        return CompressionType.NONE // unknown
    }
    
    
    func decompress(buf: [UInt8]) -> Data {
        if !self.compressed {
            return Data(buf)
        }
        
        let ty = self.compression_type
        if ty == CompressionType.LZMA {
            // TODO: LZMA decompression
            /*props, dict_size = struct.unpack("<BI", buf.read(5))
             lc = props % 9
             props = int(props / 9)
             pb = int(props / 5)
             lp = props % 5
             dec = lzma.LZMADecompressor(format=lzma.FORMAT_RAW, filters=[{
             "id": lzma.FILTER_LZMA1,
             "dict_size": dict_size,
             "lc": lc,
             "lp": lp,
             "pb": pb,
             }])
             res = dec.decompress(buf.read())
             return BytesIO(res)
             */
            print ("LZMA compressed blockinfo is currently unimplemented")
            return Data(buf)
        }
        
        if ty == .LZ4 || ty == .LZ4HC {
            let nsdata = NSData(data: Data(bytes: BinaryReader.toByteArray(self.uncompressed_size) + buf[0..<Int(self.compressed_size)] ))
            
            if let decdata = nsdata.decompressLZ4() {
                return decdata
            }
        }
        
        print("Unimplemented compression method: ")
        return Data(buf)
    }
}

public class ArchiveBlockStorage : Readable {
    
    let stream: BinaryReader
    let blocks: [ArchiveBlockInfo]
    var cursor: Int = 0
    let basepos: Int
    let maxpos: Int
    var sought: Bool
    var current_block: ArchiveBlockInfo? = nil
    var current_block_start: Int = 0
    var current_stream: BinaryReader? = nil
    
    init(blocks: [ArchiveBlockInfo], stream: BinaryReader) {
        self.blocks = blocks
        self.stream = stream
        
        self.basepos = stream.tell()
        self.maxpos = blocks.reduce(0) { $0 + Int($1.uncompressed_size) }
        
        self.sought = false
        
        self._seek(new_cursor: 0)
    }
    
    public var tell: Int {
        return self.cursor
    }
    
    public func seek(count: Int, whence: Int = 0) {
        var new_cursor: Int = 0
        if whence == 1 {
            new_cursor = count + self.cursor
        } else if whence == 2 {
            new_cursor = self.maxpos + count
        } else {
            new_cursor = count
        }
        if self.cursor != new_cursor {
            self._seek(new_cursor: new_cursor)
        }
    }
    
    private func _seek(new_cursor: Int) {
        self.cursor = new_cursor
        if !self.in_current_block(pos: new_cursor) {
            self.seek_to_block(pos: new_cursor)
        }
        
        if let cs = self.current_stream {
            let k = new_cursor - self.current_block_start
            cs.seek(count: Int32(k))
        }
    }
    
    func in_current_block(pos: Int) -> Bool {
        if let cb = self.current_block {
            let end = self.current_block_start + cb.uncompressed_size
            return (self.current_block_start <= pos) && (pos < Int(end))
        }
        return false
    }
    
    func seek_to_block(pos: Int) {
        var baseofs: Int32 = 0
        var ofs: Int32 = 0
        for b in self.blocks {
            if Int(ofs + b.uncompressed_size) > pos {
                self.current_block = b
                break
                
            }
            baseofs += b.compressed_size
            ofs += b.uncompressed_size
        }
        
        self.stream.seek(count: self.basepos + baseofs)
        if let cb = self.current_block {
            let buf = self.stream.readBytes(count: Int(cb.compressed_size))
            self.current_stream = BinaryReader(data: UPData(withData:cb.decompress(buf: buf)))
        }
    }
    
    public func readBytes(count: Int) -> [UInt8] {
        return stream.readBytes(count: count)
    }
    
}

