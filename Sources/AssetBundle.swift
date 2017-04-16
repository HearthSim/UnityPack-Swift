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
    unowned let environment: UnityEnvironment
    
    public var assets = [Asset]()
    public var name: String?
    
    private var signature: FileSignature?
    private var formatVersion: Int32 = 0
    private var unityVersion = ""
    private var generatorVersion = ""
    
    // unity fs params
    private var unityfsDescriptor = UnityfsDescriptor()
    
    // raw params
    var rawDescriptor = RawDescriptor()
    
    struct UnityfsDescriptor {
        var fsFileSize: Int64 = 0
        var ciblockSize: UInt32 = 0
        var uiblockSize: UInt32 = 0
    }
    
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
        self.unityfsDescriptor = UnityfsDescriptor()
        
        unityfsDescriptor.fsFileSize = buf.readInt64()
        unityfsDescriptor.ciblockSize = buf.readUInt()
        unityfsDescriptor.uiblockSize = buf.readUInt()
        
        let flags = buf.readUInt()
        guard let compression = CompressionType(rawValue: flags & 0x3F) else { return }
        
        guard let data = try self.readCompressedData(buf: buf, compression: compression, blockSize: unityfsDescriptor.uiblockSize) else { return }
        
        let blk = BinaryReader(data: UPData(withData: data))
        let _ = blk.readBytes(count: 16) // guid
        let numBlocks = blk.readInt()

        // read Archive block infos
        var blocks = [ArchiveBlockInfo]()
        for _ in 1 ... numBlocks {
            let busize = blk.readInt()
            let bcsize = blk.readInt()
            let bflags = blk.readInt16()
            blocks.append(ArchiveBlockInfo(uncompressedSize: busize, compressedSize: bcsize, flags: bflags))
        }

        // Read Asset data infos
        let numNodes = blk.readInt()
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
        for _ in 1 ... numNodes {
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
            self.name = assets[0].name
        }
    }
    
    struct RawDescriptor {
        var fileSize: UInt32 = 0
        var headerSize: Int32 = 0
        var fileCount: Int32 = 0
        var bundleCount: Int32 = 0
        var bundleSize: UInt32 = 0
        var uncompressedBundleSize: UInt32 = 0
        var compressedFileSize: UInt32 = 0
        var assetHeaderSize: UInt32 = 0
        var numAssets: UInt32 = 0
    }
    
    private func loadRaw(buf: BinaryReader) {
        self.rawDescriptor = RawDescriptor()
        
        rawDescriptor.fileSize = buf.readUInt()
        rawDescriptor.headerSize = buf.readInt()
        
        rawDescriptor.fileCount = buf.readInt()
        rawDescriptor.bundleCount = buf.readInt()
        
        if self.formatVersion >= 2 {
            rawDescriptor.bundleSize = buf.readUInt()
            
            if self.formatVersion >= 3 {
                rawDescriptor.uncompressedBundleSize = buf.readUInt()
            }
        }
        
        if rawDescriptor.headerSize >= 60 {
            rawDescriptor.compressedFileSize = buf.readUInt()
            rawDescriptor.assetHeaderSize = buf.readUInt()
        }
        
        let _ = buf.readInt()
        let _ = buf.readBytes(count: 1)
        self.name = buf.readString()
        
        // preload assets
        buf.seek(count: Int(rawDescriptor.headerSize))

        if !self.compressed {
            rawDescriptor.numAssets = buf.readUInt()
        } else {
            rawDescriptor.numAssets = 1
        }
        
        let asset = Asset(fromBundle: self, buf: buf)
        assets.append(asset)
    }
    
    private func readCompressedData(buf: BinaryReader, compression: CompressionType, blockSize: UInt32) throws -> Data? {
        let rawData = NSData(data: Data(bytes: BinaryReader.toByteArray(blockSize) + buf.readBytes(count: Int(self.unityfsDescriptor.ciblockSize) )))
        
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
    
    let uncompressedSize: Int32
    let compressedSize: Int32
    let flags: Int16
    
    init(uncompressedSize: Int32, compressedSize: Int32, flags: Int16) {
        self.uncompressedSize = uncompressedSize
        self.compressedSize = compressedSize
        self.flags = flags
    }
    
    var compressed: Bool {
        return self.compressionType != CompressionType.NONE
    }
    
    var compressionType: CompressionType {
        if let ct = CompressionType(rawValue: UInt32(self.flags & 0x3f)) {
            return ct
        }
        return CompressionType.NONE // unknown
    }
    
    
    func decompress(buf: [UInt8]) -> Data {
        if !self.compressed {
            return Data(bytes: buf)
        }
        
        let cType = self.compressionType
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
            let rawData = NSData(data: Data(bytes: BinaryReader.toByteArray(self.uncompressedSize) + buf[0..<Int(self.compressedSize)] ))
            
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
        
        self.basepos = stream.tell
        // sum up all block uncompressed sizes
        self.maxpos = blocks.reduce(0) { $0 + Int($1.uncompressedSize) }
        
        self.sought = false
        
        self.seek(new_cursor: 0)
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
            self.seek(new_cursor: new_cursor)
        }
    }
    
    private func seek(new_cursor: Int) {
        self.cursor = new_cursor
        if !self.isInCurrentBlock(pos: new_cursor) {
            self.seek_to_block(pos: new_cursor)
        }
        
        if let cs = self.current_stream {
            let k = new_cursor - self.current_block_start
            cs.seek(count: k)
        }
    }
    
    func isInCurrentBlock(pos: Int) -> Bool {
        if let cb = self.current_block {
            let end = self.current_block_start + Int(cb.uncompressedSize)
            return (self.current_block_start <= pos) && (pos < Int(end))
        }
        return false
    }
    
    func seek_to_block(pos: Int) {
        var baseofs: Int32 = 0
        var ofs: Int32 = 0
        for b in self.blocks {
            if Int(ofs + b.uncompressedSize) > pos {
                self.current_block = b
                break
                
            }
            baseofs += b.compressedSize
            ofs += b.uncompressedSize
        }
        
        self.stream.seek(count: self.basepos + Int(baseofs))
        if let cb = self.current_block {
            let buf = self.stream.readBytes(count: Int(cb.compressedSize))
            
            self.current_stream = BinaryReader(data: UPData(withData:cb.decompress(buf: buf)))
        }
    }
    
    public func readBytes(count: Int) -> [UInt8] {
        var buf = [UInt8]()
        var size = count
        while size != 0 && self.cursor < self.maxpos {
            if !self.isInCurrentBlock(pos: self.cursor) {
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

