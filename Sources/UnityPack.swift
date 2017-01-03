//
//  UnityPack.swift
//  UnityPack-Swift
//
//  Created by Benjamin Michotte on 3/01/17.
//  Copyright © 2017 Benjamin Michotte. All rights reserved.
//

import Foundation
import Cocoa
import Compression

public typealias Byte = UInt8

/** Available Compression Algorithms
 - Compression.lz4   : Fast compression
 - Compression.zlib  : Balanced between speed and compression
 - Compression.lzma  : High compression
 - Compression.lzfse : Apple-specific high performance compression. Faster and better compression than ZLIB, but slower than LZ4 and does not compress as well as LZMA.
 */
enum Compression {

    /// Fast compression
    case lz4

    /// Balanced between speed and compression
    case zlib

    /// High compression
    case lzma

    /// Apple-specific high performance compression. Faster and better compression than ZLIB, but slower than LZ4 and does not compress as well as LZMA.
    case lzfse
}

extension Data {


    /// Returns a Data object initialized by decompressing the data from the file specified by `path`. Attempts to determine the appropriate decompression algorithm using the path's extension.
    ///
    /// This method is equivalent to `Data(contentsOfArchive:usingCompression:)` with `nil compression`
    ///
    ///     let data = Data(contentsOfArchive: absolutePathToFile)
    ///
    /// - Parameter contentsOfArchive: The absolute path of the file from which to read data
    /// - Returns: A Data object initialized by decompressing the data from the file specified by `path`. Returns `nil` if decompression fails.
    init?(contentsOfArchive path: String) {
        self.init(contentsOfArchive: path, usedCompression: nil)
    }


    /// Returns a Data object initialized by decompressing the data from the file specified by `path` using the given `compression` algorithm.
    ///
    ///     let data = Data(contentsOfArchive: absolutePathToFile, usedCompression: Compression.lzfse)
    ///
    /// - Parameter contentsOfArchive: The absolute path of the file from which to read data
    /// - Parameter usedCompression: Algorithm to use during decompression. If compression is nil, attempts to determine the appropriate decompression algorithm using the path's extension
    /// - Returns: A Data object initialized by decompressing the data from the file specified by `path` using the given `compression` algorithm. Returns `nil` if decompression fails.
    init?(contentsOfArchive path: String, usedCompression: Compression?) {
        let pathURL = URL(fileURLWithPath: path)

        // read in the compressed data from disk
        guard let compressedData = try? Data(contentsOf: pathURL) else {
            return nil
        }

        // if compression is set use it
        let compression: Compression
        if usedCompression != nil {
            compression = usedCompression!
        }
        else {
            // otherwise, attempt to use the file extension to determine the compression algorithm
            switch pathURL.pathExtension.lowercased() {
            case "lz4"  :	compression = Compression.lz4
            case "zlib" :	compression = Compression.zlib
            case "lzma" :	compression = Compression.lzma
            case "lzfse":	compression = Compression.lzfse
            default:		return nil
            }
        }

        // finally, attempt to uncompress the data and initalize self
        if let uncompressedData = compressedData.uncompressed(using: compression) {
            self = uncompressedData
        }
        else {
            return nil
        }
    }


    /// Returns a Data object created by compressing the receiver using the given compression algorithm.
    ///
    ///     let compressedData = someData.compressed(using: Compression.lzfse)
    ///
    /// - Parameter using: Algorithm to use during compression
    /// - Returns: A Data object created by encoding the receiver's contents using the provided compression algorithm. Returns nil if compression fails or if the receiver's length is 0.
    func compressed(using compression: Compression) -> Data? {
        return self.data(using: compression, operation: .encode)
    }

    /// Returns a Data object by uncompressing the receiver using the given compression algorithm.
    ///
    ///     let uncompressedData = someCompressedData.uncompressed(using: Compression.lzfse)
    ///
    /// - Parameter using: Algorithm to use during decompression
    /// - Returns: A Data object created by decoding the receiver's contents using the provided compression algorithm. Returns nil if decompression fails or if the receiver's length is 0.
    func uncompressed(using compression: Compression) -> Data? {
        return self.data(using: compression, operation: .decode)
    }


    private enum CompressionOperation {
        case encode
        case decode
    }

    private func data(using compression: Compression, operation: CompressionOperation) -> Data? {

        guard self.count > 0 else {
            return nil
        }

        let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        var stream = streamPtr.pointee
        var status : compression_status
        var op : compression_stream_operation
        var flags : Int32
        var algorithm : compression_algorithm

        switch compression {
        case .lz4:
            algorithm = COMPRESSION_LZ4
        case .lzfse:
            algorithm = COMPRESSION_LZFSE
        case .lzma:
            algorithm = COMPRESSION_LZMA
        case .zlib:
            algorithm = COMPRESSION_ZLIB
        }

        switch operation {
        case .encode:
            op = COMPRESSION_STREAM_ENCODE
            flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
        case .decode:
            op = COMPRESSION_STREAM_DECODE
            flags = 0
        }

        status = compression_stream_init(&stream, op, algorithm)
        guard status != COMPRESSION_STATUS_ERROR else {
            // an error occurred
            return nil
        }

        let outputData = withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Data? in
            // setup the stream's source
            stream.src_ptr = bytes
            stream.src_size = count

            // setup the stream's output buffer
            // we use a temporary buffer to store the data as it's compressed
            let dstBufferSize : size_t = 4096
            let dstBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstBufferSize)
            stream.dst_ptr = dstBufferPtr
            stream.dst_size = dstBufferSize
            // and we store the output in a mutable data object
            var outputData = Data()


            repeat {
                status = compression_stream_process(&stream, flags)

                switch status {
                case COMPRESSION_STATUS_OK:
                    // Going to call _process at least once more, so prepare for that
                    if stream.dst_size == 0 {
                        // Output buffer full...

                        // Write out to outputData
                        outputData.append(dstBufferPtr, count: dstBufferSize)

                        // Re-use dstBuffer
                        stream.dst_ptr = dstBufferPtr
                        stream.dst_size = dstBufferSize
                    }

                case COMPRESSION_STATUS_END:
                    // We are done, just write out the output buffer if there's anything in it
                    if stream.dst_ptr > dstBufferPtr {
                        outputData.append(dstBufferPtr, count: stream.dst_ptr - dstBufferPtr)
                    }

                case COMPRESSION_STATUS_ERROR:
                    return nil

                default:
                    break
                }

            } while status == COMPRESSION_STATUS_OK

            return outputData
        }

        compression_stream_destroy(&stream)

        return outputData
    }

}

enum ByteOrder {
    case bigEndian
    case littleEndian

    static let nativeByteOrder: ByteOrder = (Int(CFByteOrderGetCurrent()) == Int(CFByteOrderLittleEndian.rawValue)) ? .littleEndian : .bigEndian
}


class ByteBackpacker {

    fileprivate static let referenceTypeErrorString = "TypeError: Reference Types are not supported."


    open class func unpack<T: Any>(_ valueByteArray: [Byte], byteOrder: ByteOrder = .nativeByteOrder) -> T {
        //assert(!(type(of: T.self) is AnyObject), referenceTypeErrorString) // does not work in Swift 3
        let bytes = (byteOrder == .littleEndian) ? valueByteArray : valueByteArray.reversed()
        return bytes.withUnsafeBufferPointer {
            return $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
                $0.pointee
            }
        }
    }


    open class func unpack<T: Any>(_ valueByteArray: [Byte], toType type: T.Type, byteOrder: ByteOrder = .nativeByteOrder) -> T {
        //assert(!(T.self is AnyObject), referenceTypeErrorString) // does not work in Swift 3
        let bytes = (byteOrder == .littleEndian) ? valueByteArray : valueByteArray.reversed()
        return bytes.withUnsafeBufferPointer {
            return $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
                $0.pointee
            }
        }
    }


    open class func pack<T: Any>( _ value: T, byteOrder: ByteOrder = .nativeByteOrder) -> [Byte] {
        //assert(!(T.self is AnyObject), referenceTypeErrorString) // does not work in Swift 3
        var value = value // inout works only for var not let types
        let valueByteArray = withUnsafePointer(to: &value) {
            Array(UnsafeBufferPointer(start: $0.withMemoryRebound(to: Byte.self, capacity: 1){$0}, count: MemoryLayout<T>.size))
        }
        return (byteOrder == .littleEndian) ? valueByteArray : valueByteArray.reversed()
    }
}


extension Data {

    func toByteArray() -> [Byte] {
        let count = self.count / MemoryLayout<Byte>.size
        var array = [Byte](repeating: 0, count: count)
        copyBytes(to: &array, count:count * MemoryLayout<Byte>.size)
        return array
    }

    func scanValue<T>(start: Int, length: Int) -> T {
        var bytes = [UInt8](repeating:0, count: length)
        copyBytes(to: &bytes, from: start..<start+length)
        return bytes.reversed().withUnsafeBufferPointer {
            return $0.baseAddress!.withMemoryRebound(to: T.self, capacity: 1) {
                $0.pointee
            }
        }
    }
}

class BinaryReader {
    var fileData: Data
    var location: Int

    init(data: Data) {
        self.fileData = data
        self.location = 0
    }

    func readBytes(count: Int) -> [UInt8] {
        if location >= fileData.count {
            return [UInt8]()
        }

        let startIndex = location
        let endIndex = location + count

        var bytes = [UInt8](repeating:0, count: count)
        fileData.copyBytes(to: &bytes, from: startIndex..<endIndex)

        location += count
        return bytes
    }

    func seek(_ count: Int32) {
        location = Int(count)
    }

    func readUInt8() -> UInt8 {
        var bytes = readBytes(count: 1)
        return bytes[0]
    }

    func readInt() -> Int32 {
        let int: Int32 = fileData.scanValue(start: location, length: 4)
        location += 4
        return int
    }

    func readInt16() -> Int16 {
        let int: Int16 = fileData.scanValue(start: location, length: 2)
        location += 2
        return int
    }

    func readInt64() -> Int64 {
        let int: Int64 = fileData.scanValue(start: location, length: 8)
        location += 8
        return int
        /*let bytes = readBytes(count: 8)
         return ByteBackpacker.unpack(bytes, toType: Int64.self, byteOrder: .bigEndian)*/
    }

    func readUInt() -> UInt32 {
        /*let bytes = readBytes(count: 4)
         return ByteBackpacker.unpack(bytes, toType: UInt32.self, byteOrder: .bigEndian)*/
        let int: UInt32 = fileData.scanValue(start: location, length: 4)
        location += 4
        return int
    }

    func readString() -> String {
        var bytes:[UInt8] = []

        while true {
            if let byte = readBytes(count: 1).first {
                if UInt32(byte) == ("\0" as UnicodeScalar).value {
                    break
                }
                bytes.append(byte)
            } else {
                break
            }
        }

        print("Bytes: \(bytes)")
        //print("\(MemoryLayout<String>.size)")
        //let bytes = readBytes(count: 8)

        let string = String(bytes: bytes, encoding: .utf8)?
            .characters.filter { $0 != "\0" }
            .map { String($0) }
            .joined()
        print("String : \(string)")
        return string ?? ""
    }
}

class Asset {
    class func fromBundle(bundle: BinaryReader, with: UnityPack) {

    }
}

enum CompressionType: Int {
    case none = 0,
    lzma = 1,
    lz4 = 2,
    lz4hc = 3,
    lzham = 4
}

public class UnityPack {
    var data: Data
    var binaryReader: BinaryReader
    var signature = ""
    var formatVersion: Int32 = 0
    var unityVersion = ""
    var generatorVersion = ""
    var fileSize: UInt32 = 0
    var headerSize: Int32 = 0
    var fileCount: Int32 = 0
    var bundleCount: Int32 = 0
    var bundleSize: UInt32 = 0
    var uncompressedBundleSize: UInt32 = 0
    var compressedFileSize: UInt32 = 0
    var assetHeaderSize: UInt32 = 0
    var numAssets: Int32 = 0
    var fsFileSize: Int64 = 0
    var ciblockSize: UInt32 = 0
    var uiblockSize: UInt32 = 0
    var flags: UInt32 = 0
    var guid: [UInt8] = []

    let SIGNATURE_RAW = "UnityRaw"
    let SIGNATURE_WEB = "UnityWeb"
    let SIGNATURE_FS = "UnityFS"

    public init(data: Data) {
        self.data = data
        binaryReader = BinaryReader(data: data)
    }

    public func load() {
        signature = binaryReader.readString()
        formatVersion = binaryReader.readInt()
        unityVersion = binaryReader.readString()
        generatorVersion = binaryReader.readString()

        if isUnityfs {
            loadUnityFs()
        } else {
            loadRaw()
        }
    }

    private func loadRaw() {
        fileSize = binaryReader.readUInt()
        headerSize = binaryReader.readInt()
        fileCount = binaryReader.readInt()
        bundleCount = binaryReader.readInt()

        if formatVersion >= 2 {
            bundleSize = binaryReader.readUInt()
            if formatVersion >= 3 {
                uncompressedBundleSize = binaryReader.readUInt()
            }
        }

        if headerSize >= 60 {
            compressedFileSize = binaryReader.readUInt()
            assetHeaderSize = binaryReader.readUInt()
        }

        binaryReader.readInt()
        binaryReader.readUInt8()

        binaryReader.seek(headerSize)
        if !isCompressed {
            numAssets = binaryReader.readInt()
        } else {
            numAssets = 1
        }

        //for i in 0...numAssets {
        //    let asset = Asset.fromBundle(bundle: binaryReader, with: self)
        //}
    }

    private func loadUnityFs() {
        fsFileSize = binaryReader.readInt64()
        ciblockSize = binaryReader.readUInt()
        uiblockSize = binaryReader.readUInt()
        flags = binaryReader.readUInt()
        let compression = CompressionType(rawValue: Int(flags & 0x3F)) ?? .none

        guard let data = readCompressedData(compression) else { return }
        // data is always nil :/
        // wtf

        let reader = BinaryReader(data: data)
        guid = reader.readBytes(count: 16)
        let numBlocks = reader.readInt()


        /*var blocks: [(Int, Int, Int16)] = []
         for _ in 0...numBlocks {
         let bcsize = reader.readInt()
         let busize = reader.readInt()
         let bflags = reader.readInt16()
         blocks.append((bcsize, busize, bflags))
         }
         let numNodes = reader.readInt()
         print(numNodes)*/
    }

    private func readCompressedData(_ compression: CompressionType) -> Data? {
        let data = Data(bytes: binaryReader.readBytes(count: Int(ciblockSize)))
        if compression == .none {
            return data
        }

        if compression == .lz4 || compression == .lz4hc {
            return data.uncompressed(using: .lz4)
        }
        
        return nil
    }
    
    var isCompressed: Bool {
        return signature == "UnityWeb"
    }
    
    var isUnityfs: Bool {
        return signature == SIGNATURE_FS
    }
}
