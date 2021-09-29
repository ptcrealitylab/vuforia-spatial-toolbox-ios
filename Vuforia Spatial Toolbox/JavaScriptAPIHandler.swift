//
//  JavaScriptAPIHandler.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/9/21.
//

import Foundation
import UIKit
import AudioToolbox

protocol JavaScriptCallbackDelegate {
    func callJavaScriptCallback(callback: String?, arguments: [String])
}

class JavaScriptAPIHandler {
    
    // MARK: - Singleton Initialization
    static let shared = JavaScriptAPIHandler()
    var delegate: JavaScriptCallbackDelegate?
    
    private init() {
        print("init JavaScriptAPIHandler")
    }
    
    // MARK: - Process Requests
    
    func processRequest(functionName: String, arguments: [String:Any]?, callback: String?) {
//        print("processRequest: \(functionName) with arguments: \(arguments ?? [:]) and callback: \(callback ?? "nil")")
        
        switch functionName {
        case "getDeviceReady":
            getDeviceReady(callback: callback)
        case "getVuforiaReady":
            getVuforiaReady(callback: callback)
        case "addNewMarker":
            if let args = arguments {
                let markerName = args["markerName"] as? String
                addNewMarker(markerName: markerName, callback: callback)
            }
        case "addNewMarkerJPG":
            if let args = arguments {
                let markerName = args["markerName"] as? String
                let objectID = args["objectID"] as? String
                let targetWidthMeters = args["targetWidthMeters"] as? Double
                addNewMarkerJPG(markerName: markerName, objectID: objectID, targetWidthMeters: targetWidthMeters, callback: callback)
            }
        case "getProjectionMatrix":
            getProjectionMatrix(callback: callback)
        case "getMatrixStream":
            getMatrixStream(callback: callback)
        case "getCameraMatrixStream":
            getCameraMatrixStream(callback: callback)
        case "acceptGroundPlaneAndStop":
            acceptGroundPlaneAndStop()
        case "getScreenshot":
            if let args = arguments {
                let size = (args["size"] as? String) ?? "S"
                getScreenshot(size: size, callback: callback)
            }
        case "setPause":
            setPause()
        case "setResume":
            setResume()
        case "enableExtendedTracking":
            enableExtendedTracking()
        case "getUDPMessages":
            getUDPMessages(callback: callback)
        case "sendUDPMessage":
            if let args = arguments {
                let message = args["message"] as? String
                sendUDPMessage(message: message)
            }
        case "getFileExists":
            if let args = arguments {
                let fileName = args["fileName"] as? String
                getFileExists(fileName: fileName, callback: callback)
            }
        case "getFilesExist":
            if let args = arguments {
                let fileNameArray = args["fileNameArray"] as? [String]
                getFilesExist(fileNameArray: fileNameArray, callback: callback)
            }
        case "downloadFile":
            if let args = arguments {
                let fileName = args["fileName"] as? String
                downloadFile(fileName: fileName, callback: callback)
            }
        case "tap":
            tap()
        case "setStorage":
            if let args = arguments {
                let storageID = args["storageID"] as? String
                let message = args["message"] as? String
                setStorage(key: storageID, value: message)
            }
        case "getStorage":
            if let args = arguments {
                let storageID = args["storageID"] as? String
                getStorage(key: storageID, callback: callback)
            }
        case "enableOrientationChanges":
            enableOrientationChanges(callback: callback)
        case "subscribeToAppLifeCycleEvents":
            subscribeToAppLifeCycleEvents(callback: callback)
        case "restartDeviceTracker":
            restartDeviceTracker()
        case "startVideoRecording":
            if let args = arguments {
                let objectKey = args["objectKey"] as? String
                let objectIP = args["objectIP"] as? String
                let objectPort = args["objectPort"] as? Int
                startVideoRecording(objectId: objectKey, ip: objectIP, port: objectPort)
            }
        case "stopVideoRecording":
            if let args = arguments {
                let videoId = args["videoId"] as? String
                stopVideoRecording(videoId: videoId)
            }
        default:
            print("no function match detected for \(functionName)")
        }
        
    }
    
    private func stringifyEachArg(args: [String]) -> [String] {
        var stringified:[String] = []
        for i in 0 ..< args.count {
            stringified.append(stringifyArg(args[i]))
        }
        return stringified
    }
    
    private func stringifyArg(_ arg: String) -> String {
        return "\"\(arg)\""
    }
    
    // MARK: - APIs
    
    func getDeviceReady(callback: String?) {
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        
        // e.g. "iPhone12,5"
        let deviceName = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        let arguments = stringifyEachArg(args: [deviceName])
        delegate?.callJavaScriptCallback(callback: callback, arguments: arguments)
    }
    
    func getVuforiaReady(callback: String?) {
        ARManager.shared.initVuforia(completionHandler: {
            print("Vuforia is ready!")
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [])
        })
    }
    
    func addNewMarker(markerName: String?, callback: String?) {
        print("addNewMarker: \(markerName ?? "")")
//        let mockPath = "http://10.10.10.30:8080/obj/chips/target/target.xml"
        
        guard let remotePath = markerName else { return }
        
        let localPath = FileDownloadManager.shared.getTempFilePath(originalFilePath: remotePath)
        ARManager.shared.addNewMarker(markerPath: localPath) { success in
            let successString = success ? "true" : "false"
            print("addNewMarker callback triggered with success: \(success)")
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [successString, self.stringifyArg(remotePath)])
        }
    }
    
    func addNewMarkerJPG(markerName: String?, objectID: String?, targetWidthMeters: Double?, callback: String?) {
        print("addNewMarkerJPG: \(markerName ?? "")")

        guard let remotePath = markerName else { return }
        guard let objID = objectID else { return }
        guard let targetWidth = targetWidthMeters else { return }
        
        let localPath = FileDownloadManager.shared.getTempFilePath(originalFilePath: remotePath)
        ARManager.shared.addNewMarkerFromImage(markerPath: localPath, objectID: objID, targetWidthMeters: targetWidth) { success in
            let successString = success ? "true" : "false"
            print("addNewMarkerFromImage callback triggered with success: \(success)")
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [successString, self.stringifyArg(remotePath)])
        }
    }
    
    func getProjectionMatrix(callback: String?) {
        ARManager.shared.getProjectionMatrix(completionHandler: { matrixString in
//            print("JavaScriptAPIHandler got matrixString: \(matrixString)")
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [matrixString])
        })
    }
    
    func getMatrixStream(callback: String?) {
        ARManager.shared.setMatrixCompletionHandler(completionHandler: { visibleMarkers in
//            print("JavaScriptAPIHandler got visibleMarkers: \(visibleMarkers)")
            
            var javaScriptObject = "{"
            
            if visibleMarkers.count > 0 {
                for marker in visibleMarkers {
                    let markerName = marker.name
                    let markerMatrix = marker.modelMatrix
                    let trackingStatus = marker.trackingStatus
                    let trackingStatusInfo = marker.trackingStatusInfo

                    // two options - one includes tracking status, the other does not
                    
                    if (ARManager.shared.isExtendedTrackingEnabled) {
                        javaScriptObject = javaScriptObject.appending("'\(markerName)': { 'matrix': \(markerMatrix), 'status': '\(trackingStatus)', 'statusInfo': '\(trackingStatusInfo)' },")
                    } else {
                        javaScriptObject = javaScriptObject.appending("'\(markerName)': \(markerMatrix),")
                    }
                }
                javaScriptObject.remove(at: javaScriptObject.index(before: javaScriptObject.endIndex)) // remove last comma
            }
            
            javaScriptObject = javaScriptObject.appending("}")
            
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [javaScriptObject])
        })
    }
    func getCameraMatrixStream(callback: String?) {
        ARManager.shared.setCameraMatrixCompletionHandler(completionHandler: { cameraMarker in
//            print("JavaScriptAPIHandler got cameraMarker: \(cameraMarker)")

            let cameraMatrix = cameraMarker["modelViewMatrix"] ?? "[]"
            let trackingStatus = cameraMarker["trackingStatus"] ?? "null"
            let trackingStatusInfo = cameraMarker["trackingStatusInfo"] ?? "null"
            
            let javaScriptObject = "{ 'matrix': \(cameraMatrix), 'status': '\(trackingStatus)', 'statusInfo': '\(trackingStatusInfo)' }"
            
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [javaScriptObject])
        })
    }
    func getGroundPlaneMatrixStream(callback: String?) {
        ARManager.shared.setGroundPlaneMatrixCompletionHandler(completionHandler: { groundPlaneMarker in
            print("JavaScriptAPIHandler got groundPlaneMarker: \(groundPlaneMarker)")

            let groundPlaneMatrix = groundPlaneMarker["modelViewMatrix"] ?? "[]"

            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [groundPlaneMatrix])
        })
    }
    func acceptGroundPlaneAndStop() {
        ARManager.shared.stopGroundPlaneTracker()
    }
    func setPause() {
        ARManager.shared.pause()
    }
    func setResume() {
        ARManager.shared.resume()
    }
    func getScreenshot(size: String?, callback: String?) {
        print("TODO: implement getScreenshot in a faster way than the Obj-C code base")
        let screenshotString = VideoRecordingManager.shared.getScreenshot()
        delegate?.callJavaScriptCallback(callback: callback, arguments: stringifyEachArg(args: [screenshotString ?? ""]))
    }
    //func resizeImage(image: UIImage, newSize: CGSize) { // helper function for getScreenshot
    //
    //}
    func enableExtendedTracking() {
        ARManager.shared.enableExtendedTracking()
    }
    func getUDPMessages(callback: String?) {
        UDPManager.shared.setReceivedMessageCallback(completionHandler: { message in
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [message])
        })
    }
    func sendUDPMessage(message: String?) {
        if let _message = message {
            UDPManager.shared.sendUDPMessage(message: _message)
        }
    }
    func getFileExists(fileName: String?, callback: String?) {
        guard let _fileName = fileName else {
            delegate?.callJavaScriptCallback(callback: callback, arguments: ["false"])
            return
        }
        let doesFileExist = FileDownloadManager.shared.getFileExists(fileName: _fileName) ? "true" : "false"
        delegate?.callJavaScriptCallback(callback: callback, arguments: [doesFileExist])
        
    }
    func getFilesExist(fileNameArray: [String]?, callback: String?) {
        guard let _fileNameArray = fileNameArray else {
            delegate?.callJavaScriptCallback(callback: callback, arguments: ["false"])
            return
        }
        let allExist = FileDownloadManager.shared.getFilesExist(fileNameArray: _fileNameArray) ? "true" : "false"
        delegate?.callJavaScriptCallback(callback: callback, arguments: [allExist])
    }
    func downloadFile(fileName: String?, callback: String?) {
        guard let _fileName = fileName else {
            delegate?.callJavaScriptCallback(callback: callback, arguments: ["false"])
            return
        }
        FileDownloadManager.shared.downloadFile(fileName: _fileName, callback: { success in
            print("file download success = \(success), for file: \(_fileName)")
            let successString = success ? "true" : "false"
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: [successString, self.stringifyArg(_fileName)])
        })
    }
    // deprecated
    func getChecksum(fileNameArray: [String]?, callback: String?) {
        
    }
    func setStorage(key: String?, value: String?) {
        guard let _key = key, let _value = value else {
            return
        }
        FileDownloadManager.shared.setStorage(key: _key, value: _value)
    }
    func getStorage(key: String?, callback: String?) {
        guard let _key = key else {
            return
        }
        let value = FileDownloadManager.shared.getStorage(key: _key) ?? "null"
        delegate?.callJavaScriptCallback(callback: callback, arguments: self.stringifyEachArg(args: [value]))
    }
    // deprecated
    func startSpeechRecording() {
        
    }
    // deprecated
    func stopSpeechRecording() {
        
    }
    // deprecated
    func addSpeechListener(callback: String?) {
        
    }
    func startVideoRecording(objectId: String?, ip: String?, port: Int?) {
        guard let _id = objectId,
              let _ip = ip,
              let _port = port else { return }
        
        VideoRecordingManager.shared.startRecording(objectKey: _id, ip: _ip, port: String(_port))
    }
    func stopVideoRecording(videoId: String?) {
        guard let _videoId = videoId else { return }
        
        VideoRecordingManager.shared.stopRecording(videoID: _videoId)
    }
    func tap() {
        if (UIDevice.current.model == "iPhone") {
            AudioServicesPlaySystemSound(1519)
        } else {
            AudioServicesPlaySystemSound(1105)
        }
    }
    func focusCamera() {
        
    }
    func tryPlacingGroundAnchor(normalizedScreenX: String?, normalizedScreenY: String?, callback: String?) {
        
    }
    // deprecated
    func loadNewUI(reloadURL: String?) {
        
    }
    // deprecated
    func clearCache() {
        
    }
    func enableOrientationChanges(callback: String?) {
        DeviceStateManager.shared.enableOrientationChanges { orientationString in
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: self.stringifyEachArg(args: [orientationString]))
        }
    }
    func subscribeToAppLifeCycleEvents(callback: String?) {
        DeviceStateManager.shared.subscribeToAppLifeCycleEvents { eventName in
            self.delegate?.callJavaScriptCallback(callback: callback, arguments: self.stringifyEachArg(args: [eventName]))
        }
    }
    func restartDeviceTracker() {
        // TODO: implement this, it's already getting called when phone tracking is bad
    }
}
