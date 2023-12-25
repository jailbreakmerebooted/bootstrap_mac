import Foundation
import libzstd

func isRunningAsRoot() -> Bool {
    return geteuid() == 0
}

guard isRunningAsRoot() else {
    print("This script must be run as root.")
    exit(EXIT_FAILURE)
}
func revertZshProfilesInUsersDirectory() {
    let usersDirectory = "/Users"

    do {
        let userDirectories = try FileManager.default.contentsOfDirectory(atPath: usersDirectory)

        for username in userDirectories {
            let zprofilePath = "\(usersDirectory)/\(username)/.zprofile"
            let skelZprofilePath = "/etc/skel/.zprofile"

            do {
                // Remove existing .zprofile file
                try FileManager.default.removeItem(atPath: zprofilePath)

                // Copy default .zprofile content to the user's directory
                let skelZprofileContent = try String(contentsOfFile: skelZprofilePath, encoding: .utf8)
                try skelZprofileContent.write(toFile: zprofilePath, atomically: true, encoding: .utf8)

            } catch {
            }
        }
    } catch {
    }
}
func downloadFile(withURL url: URL, to destinationPath: String) {
    let task = URLSession.shared.downloadTask(with: url) { (tempURL, response, error) in
        if let error = error {
            print("Error downloading file: \(error)")
            return
        }

        guard let tempURL = tempURL else {
            print("Error: No temporary URL provided.")
            return
        }

        let destinationURL = URL(fileURLWithPath: destinationPath)

        do {
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            print("[+] bootstrap downloaded successfully")
            print("[*] decompressing bootstrap stage [1/3]")
            decompressAndSaveZstdFile(inputFilePath: destinationPath)
        } catch {
            print("Error moving file to destination: \(error)")
        }
    }

    let progress = Progress(totalUnitCount: 100)
    progress.cancellationHandler = {
        task.cancel()
        print("Download canceled.")
    }

    task.resume()

    while !progress.isFinished {
        usleep(100_000) // Sleep for 100 milliseconds
    }

    print("[+] bootstrap downloaded successfully")
}
func deleteEverything(atPath path: String) {
    let fileManager = FileManager.default
    
    do {
        try fileManager.removeItem(atPath: path)
        print("Deleted everything in: \(path)")
    } catch {
        print("Error deleting everything in \(path): \(error)")
    }
}
func deleteContents(atPath path: String) {
    let fileManager = FileManager.default
    
    do {
        let contents = try fileManager.contentsOfDirectory(atPath: path)
        for item in contents {
            let itemPath = (path as NSString).appendingPathComponent(item)
            try fileManager.removeItem(atPath: itemPath)
            //print("Deleted: \(itemPath)")
        }
        //print("Deleted everything inside: \(path)")
    } catch {
        //print("Error deleting contents in \(path): \(error)")
    }
}

// Example usage:
let fileURL = URL(string: "https://apt.procurs.us/bootstraps/big_sur/bootstrap-darwin-arm64.tar.zst")!
let destinationPath = "/opt/bootstrap.tar.zst"

deleteContents(atPath: "/opt")
print("[+] cleaned up /opt")
revertZshProfilesInUsersDirectory()
print("[+] reverted zsh profile to default")
print("[+] mac unbootstrapped")
downloadFile(withURL: fileURL, to: destinationPath)
