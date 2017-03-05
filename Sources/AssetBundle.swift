//
//  AssetBundle.swift
//  UnityPack-Swift
//
//  Created by Istvan Fehervari on 05/01/2017.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation

enum AssetBundleError: Error {
    case FileReadingError
}

public class AssetBundle: CustomStringConvertible {
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
        
        guard let fileHandle = FileHandle(forReadingAtPath: filePath) else {
            throw AssetBundleError.FileReadingError
        }
        self.path = (filePath as NSString).lastPathComponent
        
        let buf = BinaryReader(data: FileData(withFileHandle: fileHandle))
        
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
        let _ = blk.readBytes(count: 16) // guid
        let num_blocks = blk.readInt()

        // read Archive block infos
        var blocks = [ArchiveBlockInfo]()
        for _ in 1 ... num_blocks {
            let busize = blk.readInt()
            let bcsize = blk.readInt()
            let bflags = blk.readInt16()
            blocks.append(ArchiveBlockInfo(uncompressedSize: busize, compressedSize: bcsize, flags: bflags))
        }

        // Read Asset data infos
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

        // read block storage
        let storage = ArchiveBlockStorage(blocks: blocks, stream: buf)
        for info in nodes {
            storage.seek(count: info.ofs)
            let asset = Asset(fromBundle: self, buf: storage)
            asset.name = info.name
            self.assets.append(asset)
        }
        
        // Hacky
        if self.assets.count > 0 {
            self.name = self.assets[0].name
        }
    }
    
    private func loadRaw(buf: BinaryReader) {
        // TODO: loading raw data
        fatalError("Error: reading raw data is not yet implemented!")
    }
    
    private func readCompressedData(buf: BinaryReader, compression: CompressionType, blockSize: UInt32) throws -> Data? {
        let rawData = NSData(data: Data(bytes: BinaryReader.toByteArray(blockSize) + buf.readBytes(count: Int(ciblockSize) )))
        
        if compression == .none {
            return Data(referencing: rawData)
        }
        
        if compression == .LZ4 || compression == .LZ4HC {
            return rawData.decompressLZ4();
        }
        
        return nil
    }
}

class ArchiveBlockInfo {
    
    let uncompressed_size: Int32
    let compressed_size: Int32
    let flags: Int16
    
    init(uncompressedSize: Int32, compressedSize: Int32, flags: Int16) {
        self.uncompressed_size = uncompressedSize
        self.compressed_size = compressedSize
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
            return Data(bytes: buf)
        }
        
        let cType = self.compression_type
        if cType == CompressionType.LZMA {
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
            fatalError("Error: LZMA compressed blockinfo is currently unimplemented")
            //return Data(buf)
        }
        
        if cType == .LZ4 || cType == .LZ4HC {
            let rawData = NSData(data: Data(bytes: BinaryReader.toByteArray(self.uncompressed_size) + buf[0..<Int(self.compressed_size)] ))
            
            if let ucData = rawData.decompressLZ4() {
                return ucData
            }
        }
        
        print("Error: Unimplemented compression method: \(cType)")
        return Data()
    }
}

public class ArchiveBlockStorage : Readable {
    
    let stream: BinaryReader
    let blocks: [ArchiveBlockInfo] // info about blocks
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
        // sum up all block uncompressed sizes
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
        var buf = [UInt8]()
        var size = count
        while size != 0 && self.cursor < self.maxpos {
            if !self.in_current_block(pos: self.cursor) {
                self.seek_to_block(pos: self.cursor)
            }
            let part = self.current_stream!.readBytes(count: size)
            if size > 0 {
                precondition(part.count != 0, "EOFERROR")
                size -= part.count
            }
            self.cursor += part.count
            buf.append(contentsOf: part)
        }
        return buf
    }
    
}

