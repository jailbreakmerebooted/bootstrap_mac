import Foundation

func folderExists(atPath path: String) -> Bool {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    
    // Check if the item at the specified path exists and is a directory
    return fileManager.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
}
func createFolder(atPath path: String) -> Bool {
    let fileManager = FileManager.default
    try? fileManager.createDirectory(at: URL(fileURLWithPath: path), withIntermediateDirectories: true)
    if folderExists(atPath: path) {
        return true
    }
    return false
}
