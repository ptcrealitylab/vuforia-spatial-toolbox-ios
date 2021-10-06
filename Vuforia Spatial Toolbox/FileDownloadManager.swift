//
//  FileManager.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/9/21.
//

import Foundation
import AFNetworking
import MobileCoreServices

extension URL {
    func mimeType() -> String {
        let pathExtension = self.pathExtension
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
    var containsImage: Bool {
        let mimeType = self.mimeType()
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeImage)
    }
    var containsAudio: Bool {
        let mimeType = self.mimeType()
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeAudio)
    }
    var containsVideo: Bool {
        let mimeType = self.mimeType()
        guard  let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        return UTTypeConformsTo(uti, kUTTypeMovie)
    }
}

typealias SuccessCompletionHandler = (Bool) -> ()
typealias ValueCompletionHandler = (String) -> ()

class FileDownloadManager {
    
    // MARK: - Singleton
    static let shared = FileDownloadManager()
    
    // MARK: - Initialization
    
    private init() {
        print("Init FileManager");
    }
    
    // method for converting a URL to a file that was downloaded -> into a valid readable/writeable path in the NSTemporaryDirectory
    // creates any intermediate directories if needed to mirror the url /file/path/components/ including the IP address formatted as /0-0-0-0_8080/
    func getTempFilePath(originalFilePath:String) -> String {
        var pathComponents = originalFilePath.components(separatedBy: "/")
        let urlPath = URL(fileURLWithPath: originalFilePath)
        let lastPathComponent = urlPath.lastPathComponent
        var containingDirectory = urlPath.deletingLastPathComponent()
        
        // if file path is a url, convert it to a valid nested folder structure
        if (pathComponents[0] == "http:") || (pathComponents[0] == "https:") {
            pathComponents[2] = pathComponents[2].replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: ":", with: "_")
            pathComponents.removeFirst(2)
            pathComponents.removeLast()
            if let newDir = URL(string: pathComponents.joined(separator: "/")) {
                containingDirectory = newDir
            }
        }
        
        guard let tempDir = URL(string: NSTemporaryDirectory()) else { return ""; }
        containingDirectory = tempDir.appendingPathComponent(containingDirectory.absoluteString)

        do {
            // create containing directory otherwise cannot save
            try FileManager.default.createDirectory(atPath: containingDirectory.absoluteString, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("error creating directory at path: \(containingDirectory.absoluteString)")
            return ""
        }
        
        let filePath = containingDirectory.appendingPathComponent(lastPathComponent)
        return filePath.absoluteString
    }
    
    func getTempDirectoryPath(directoryName: String) -> String {
        guard let tempDir = URL(string: NSTemporaryDirectory()) else { return ""; }
        let directory = tempDir.appendingPathComponent(directoryName);
        do {
            // create containing directory otherwise cannot save
            try FileManager.default.createDirectory(atPath: directory.absoluteString, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("error creating directory at path: \(directory.absoluteString)")
            return ""
        }
        return directory.absoluteString
    }
    
    func getFileExists(fileName: String) -> Bool {
        let filePath = self.getTempFilePath(originalFilePath: fileName)
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    func getFilesExist(fileNameArray: [String]) -> Bool {
        var allExist = true
        
        for fileName in fileNameArray {
            let filePath = self.getTempFilePath(originalFilePath: fileName)
            if (!FileManager.default.fileExists(atPath: filePath)) {
                allExist = false
                break
            }
        }
        
        return allExist
    }
    
    func downloadFile(fileName: String, callback: @escaping SuccessCompletionHandler) {
        DispatchQueue.global(qos: .default).async {
            print("Downloading started")
            if let url = URL.init(string: fileName) {
                do {
                    let urlData = try Data.init(contentsOf: url)
                    let filePath = self.getTempFilePath(originalFilePath: fileName)
                    
                    let fileURL = URL.init(fileURLWithPath: filePath)
                    // saving is done on the main thread
                    DispatchQueue.main.async {
                        do {
                            try urlData.write(to: fileURL, options: .atomic)
                            callback(true)
                        } catch {
                            print(error)
                            callback(false)
                        }
                    }
                    
                } catch {
                    print(error)
                    callback(false)
                }
            } else {
                callback(false)
            }
        }
    }
    
    func setStorage(key: String, value: String) {
        UserDefaults.standard.setValue(value, forKey: key)
        print("Saved { \(key): \(value) }")
    }
    
    func getStorage(key: String) -> String? {
        if let value = UserDefaults.standard.value(forKey: key) as? String {
            print("Loaded \(value) from \(key)")
            return value
        }
        print("No value found for key: \(key)")
        return nil
    }
    
    func uploadVideoFileFromPath(_ localPath: URL, toURL destinationURL: URL) {
        print("begin video file upload")
        print("localPath: \(localPath)")
        print("destinationURL: \(destinationURL)")
        
        let doesFileExist = FileManager.default.fileExists(atPath: localPath.relativePath)
        if doesFileExist {
            print("file exists at path: \(localPath)")
        } else {
            print("file doesn't exist at path: \(localPath)")
        }
        
        let manager = AFHTTPSessionManager.init()
        manager.responseSerializer = AFHTTPResponseSerializer.init()
        
        let task = manager.post(destinationURL.absoluteString, parameters: nil) { formData in
            let randomName = "\(Int.random(in: 1 ..< 10000000))"
            print("fileName: \(randomName)")
            do {
                try formData.appendPart(withFileURL: localPath, name: randomName, fileName: randomName.appending(".mp4"), mimeType: "video/mp4")
                print("succeeded in appending part to formData")
            } catch {
                print("error appending part to formData")
            }
        } progress: { progress in
            print("upload progress: \(progress)")
        } success: { task, responseObject in
            print("upload success")
            if let responseData = responseObject as? Data {
                let result = String(data: responseData, encoding: .utf8)
                print(result ?? "no result")
            }
        } failure: { task, error in
            print("upload failure")
            print(error)
        }

        if task == nil {
            print("creation of task failed")
        }
        
        print("file upload reached end")
    }
    
    func uploadFile(named fileName: String, atPath localPath: URL, toURL destinationURL: URL, withHeaders headers: [String:String], onComplete: @escaping (Bool, String?) -> ()) {
        print("begin file upload")
        print("localPath: \(localPath)")
        print("destinationURL: \(destinationURL)")
        print("headers: \(headers)")

        let doesFileExist = FileManager.default.fileExists(atPath: localPath.relativePath)
        if doesFileExist {
            print("file exists at path: \(localPath)")
        } else {
            onComplete(false, "file doesn't exist at path: \(localPath)")
            return
        }
        
        let manager = AFHTTPSessionManager.init()
        manager.responseSerializer = AFHTTPResponseSerializer.init()
        manager.requestSerializer = AFHTTPRequestSerializer.init()
        for key in headers.keys {
            manager.requestSerializer.setValue(headers[key], forHTTPHeaderField: key)
            print("added header: { '\(key)': '\(headers[key] ?? "undefined")' }")
        }
                
        let task = manager.post(destinationURL.absoluteString, parameters: nil) { formData in
            do {
//                try formData.appendPart(withFileURL: localPath, name: randomName, fileName: randomName.appending(".mp4"), mimeType: "video/mp4")
//                try formData.appendPart(withHeaders: headers, body: T##Data)
                let inferredMimeType = localPath.mimeType()
                print("mimeType: \(inferredMimeType)")
                
                try formData.appendPart(withFileURL: localPath, name: fileName, fileName: fileName, mimeType: inferredMimeType)
                print("succeeded in appending part to formData")
            } catch {
                onComplete(false, "error appending part to formData")
                return
            }
        } progress: { progress in
            print("upload progress: \(progress)")
        } success: { task, responseObject in
            print("upload success")
            if let responseData = responseObject as? Data {
                let result = String(data: responseData, encoding: .utf8)
                print(result ?? "no result")
            }
            onComplete(true, nil)
        } failure: { task, error in
            print("upload failure")
            print(error)
            onComplete(false, error.localizedDescription)
        }

        if task == nil {
            print("creation of task failed")
            onComplete(false, "creation of task failed")
        }
        
        print("file upload reached end")
    }
    
}
