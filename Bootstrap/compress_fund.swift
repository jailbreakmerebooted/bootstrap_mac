import Foundation
import libzstd

func decompressAndSaveZstdFile(inputFilePath: String) {
    // Create output file path for decompressed data
    let outputFileName = (inputFilePath as NSString).deletingPathExtension
    let outputFilePath = outputFileName + "_decompressed" + "." + (inputFilePath as NSString).pathExtension

    // Read compressed data from file
    guard let compressedData = FileManager.default.contents(atPath: inputFilePath) else {
        print("Failed to read compressed data from file")
        return
    }

    // Estimate the decompressed size
    var dstCapacity: UInt64 = 0
    compressedData.withUnsafeBytes { srcBuffer in
        dstCapacity = ZSTD_getDecompressedSize(srcBuffer.baseAddress, compressedData.count)
    }
    guard dstCapacity > 0 else {
        print("Invalid compressed data")
        return
    }

    // Allocate buffer for decompressed data
    var decompressedData = Data(count: Int(dstCapacity))

    // Decompress the data
    decompressedData.withUnsafeMutableBytes { dstBuffer in
        compressedData.withUnsafeBytes { srcBuffer in
            let decompressedSize = ZSTD_decompress(dstBuffer.baseAddress, Int(dstCapacity), srcBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self), compressedData.count)
            guard decompressedSize > 0 else {
                print("Failed to decompress data")
                return
            }
        }
    }

    // Save decompressed data to a new file in the same directory
    FileManager.default.createFile(atPath: outputFilePath, contents: decompressedData, attributes: nil)

    print("[*] decompressing bootstrap stage [2/3]")
    renameFile(atPath: "/opt/bootstrap.tar_decompressed.zst" , to: "bootstrap.tar")
}
func renameFile(atPath filePath: String, to newName: String) {
    let fileManager = FileManager.default

    // Create the new file path with the desired name
    let newPath = (filePath as NSString).deletingLastPathComponent + "/" + newName

    do {
        // Rename the file
        try fileManager.moveItem(atPath: filePath, toPath: newPath)
        print("[*] decompressing bootstrap stage [3/3]")
        extractTarAtPath("/opt/" + newName, to: "/")
    } catch {
        print("Error renaming file: \(error)")
    }
}
func extractTarAtPath(_ tarPath: String, to extractionPath: String) {
    let process = Process()
    process.launchPath = "/usr/bin/tar"
    process.arguments = ["-xpkf", tarPath, "-C", extractionPath]

    let pipe = Pipe()
    process.standardOutput = pipe

    process.launch()
    process.waitUntilExit()

    print("[+] decompression completed")
}
