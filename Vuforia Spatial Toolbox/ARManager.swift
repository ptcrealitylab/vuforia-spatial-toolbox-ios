//
//  ARManager.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/9/21.
//

import Foundation
import UIKit

typealias CompletionHandler = () -> ()
typealias MarkerCompletionHandler = ([String:String]) -> ()
typealias MatrixStringCompletionHandler = (String) -> ()
typealias MarkerListCompletionHandler = ([ProcessedObservation]) -> ()

struct ProcessedObservation {
    var name: String
    var modelMatrix: String
    var trackingStatus: String
    var trackingStatusInfo: String

    init(_name: String, _modelMatrix: String, _trackingStatus: String, _trackingStatusInfo: String) {
        name = _name; modelMatrix = _modelMatrix; trackingStatus = _trackingStatus; trackingStatusInfo = _trackingStatusInfo;
    }
}

//MTLNewLibraryCompletionHandler = (MTLLibrary?, Error?) -> Void
class ARManager: NSObject, XMLParserDelegate, VideoRecordingSource {
    var isRecording: Bool
 
    // MARK: - Singleton Initialization
    static let shared = ARManager()
    
    var vuforiaView: VuforiaView?
    var initCompletionHandler: CompletionHandler?
    var visibleMarkersCompletionHandler: MarkerListCompletionHandler?
    var cameraMatrixCompletionHandler: MarkerCompletionHandler?
    var projectionMatrixCompletionHandler: MatrixStringCompletionHandler?
    var groundPlaneMatrixCompletionHandler: MarkerCompletionHandler?
    
    var isExtendedTrackingEnabled = false
    
    var pathToXmlContents:[String: String] = [String: String]()
    
    var targetsAdded:[String: Bool] = [String: Bool]()
    var targetCallbacks:[String: SuccessCompletionHandler] = [String: SuccessCompletionHandler]()

    struct Constants {
        static let QUIT_ON_ERROR = Notification.Name("QuitOnError")
    }
    var mTarget: Int32 = -1
    
    private override init() {
        print("init ARManager")
        isRecording = false
    }
    
    func setupVuforiaView(vuforiaView: VuforiaView?) {
        self.vuforiaView = vuforiaView
        showLoadingAnimation()
    }
    
    func showLoadingAnimation() {
        var indicatorBounds:CGRect
        let mainBounds = UIScreen.main.bounds
        let smallerBoundsSize = min(mainBounds.size.width, mainBounds.size.height)
        let largerBoundsSize = max(mainBounds.size.width, mainBounds.size.height)
        let orientation = getOrientation()
        if (orientation == UIInterfaceOrientation.unknown) {
            return
        }
        
        if (orientation.isPortrait) {
            indicatorBounds = CGRect.init(x: smallerBoundsSize / 2 - 12, y: largerBoundsSize / 2 - 12, width: 24, height: 24)
            
        } else {
            indicatorBounds = CGRect.init(x: largerBoundsSize / 2 - 12, y: smallerBoundsSize / 2 - 12, width: 24, height: 24)
        }
        
        let loadingIndicator = UIActivityIndicatorView.init(frame: indicatorBounds)
        loadingIndicator.tag  = 1;
        loadingIndicator.style = UIActivityIndicatorView.Style.large
        
        if let _vuforiaView = vuforiaView {
            _vuforiaView.addSubview(loadingIndicator)
        }
        loadingIndicator.startAnimating()
    }
    
    func hideLoadingAnimation() {
        if let _vuforiaView = vuforiaView {
            let loadingIndicator = _vuforiaView.viewWithTag(1)
            loadingIndicator?.removeFromSuperview()
        }
    }
    
    func initVuforia(completionHandler: @escaping CompletionHandler) {
        initCompletionHandler = completionHandler
        
        DispatchQueue.global(qos: .background).async {
            
            // TODO: bring back presentError
//            let errorCallback: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<Int8>?) -> Void = {(observer, errorString) -> Void in
//                let viewController = Unmanaged.fromOpaque(observer!).takeUnretainedValue() as MainViewController
//                viewController.presentError(error: errorString!)
//            };
            
            let initDoneCallback: @convention(c) (UnsafeMutableRawPointer?) -> Void = {(observer) -> Void in
//                let viewController = Unmanaged.fromOpaque(observer!).takeUnretainedValue() as MainViewController
                DispatchQueue.main.async {
                    ARManager.shared.vuforiaView?.mVuforiaStarted = startAR()
                    ARManager.shared.hideLoadingAnimation()
                    
                    if let callback = ARManager.shared.initCompletionHandler {
                        callback()
                    }
                }
            }

            var initConfig: VuforiaInitConfig = VuforiaInitConfig()
            initConfig.classPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            // TODO: bring back errorCallback
//            initConfig.errorCallback = errorCallback
            initConfig.initDoneCallback = initDoneCallback
            initConfig.vbRenderBackend = VuRenderVBBackendType(VU_RENDER_VB_BACKEND_METAL)
            
            initAR(initConfig, self.mTarget)
        }
    }
    
    func pause() {
        stopAR()
    }
    
    func resume() {
        startAR()
    }
    
    func stop() {
        stopAR()
        deinitAR()
    }
    
    func addNewMarker(markerPath: String, completionHandler: @escaping SuccessCompletionHandler) {
        print("ARManager: addNewMarker")
        print(markerPath)
        
        let path = URL.init(fileURLWithPath: markerPath)
        
        // determine what type of trackable it is by reading target.xml
        // the parsing functions actually add the target to vuforia, so we don't need to do that here
        
        do {
            let xmlContents = try String.init(contentsOfFile: markerPath, encoding: .utf8)
            print(xmlContents)
            
            // store info to lookup after parsing
            pathToXmlContents[markerPath] = xmlContents
            targetCallbacks[markerPath] = completionHandler
            
            let parser = XMLParser(contentsOf: path)
            parser?.delegate = self
            let success = parser?.parse()
            if success != nil {
                print("parsing success")
                // don't completionHandler(true) here... call that in the parse function if the target successfully gets created
            } else {
                print("parsing failure")
                completionHandler(false)
            }
        } catch {
            print("error reading xml", error)
            completionHandler(false)
        }
    }
    
    private func getFilePathForName(_ targetName: String) -> String? {
        for (filePath, xmlString) in pathToXmlContents {
            if (xmlString.contains(targetName)) {
                return filePath
            }
        }
        return nil
    }
    
    func addNewMarkerFromImage(markerPath: String, objectID: String, targetWidthMeters: Double, completionHandler: @escaping SuccessCompletionHandler) {
        print("ARManager: addNewMarkerFromImage")
//        return addImageTarget(markerPath, targetName)
        let markerXmlPath = markerPath.replacingOccurrences(of: "jpg", with: "xml")
        let path = URL.init(fileURLWithPath: markerPath)
        let xmlPath = URL.init(fileURLWithPath: markerXmlPath)
        
        // determine what type of trackable it is by reading target.xml
        // the parsing functions actually add the target to vuforia, so we don't need to do that here
        
        do {
            let xmlContents = try String.init(contentsOfFile: markerXmlPath, encoding: .utf8)
            print(xmlContents)
            
            // store info to lookup after parsing
            pathToXmlContents[markerPath] = xmlContents
            targetCallbacks[markerPath] = completionHandler
            
            let parser = XMLParser(contentsOf: xmlPath)
            parser?.delegate = self
            let success = parser?.parse()
            if success != nil {
                print("parsing success")
                // don't completionHandler(true) here... call that in the parse function if the target successfully gets created
            } else {
                print("parsing failure")
//                completionHandler(false)
            }
        } catch {
            print("error reading xml", error)
//            completionHandler(false)
        }
    }
    
    private func processTrackableObservation(_ observation : TrackableObservation) -> ProcessedObservation? {

        guard let name = observation.name,
           let modelMatrix = observation.modelMatrix,
           let trackingStatus = observation.trackingStatus,
           let trackingStatusInfo = observation.trackingStatusInfo else {
            print("error getting fields from observation")
            return nil
        }
            
        // cast to String
        guard let sName = String(utf8String: name) else {
            print("error casting name to String")
            return nil
        }
        guard let sTrackingStatus = String(utf8String: trackingStatus) else {
            print("error casting trackingStatus to String")
            return nil
        }
        guard let sTrackingStatusInfo = String(utf8String: trackingStatusInfo) else {
            print("error casting trackingStatusInfo to String")
            return nil
        }
        guard let sModelMatrix = String(utf8String: modelMatrix) else {
            print("error casting modelViewMatrix to String")
            return nil
        }

        return ProcessedObservation(_name: sName, _modelMatrix: sModelMatrix, _trackingStatus: sTrackingStatus, _trackingStatusInfo: sTrackingStatusInfo)
    }
    
    func setMatrixCompletionHandler(completionHandler: @escaping MarkerListCompletionHandler) {
        visibleMarkersCompletionHandler = completionHandler
        print("set visibleMarkersCompletionHandler")
        
        // Uses callback pattern from http://www.perry.cz/clanky/swift.html
        // and https://stackoverflow.com/questions/33294620/how-to-cast-self-to-unsafemutablepointervoid-type-in-swift
        setVisibleMarkersCallback(bridge(self), {(observer, trackableObservations, numObservations) -> Void in
            // Extract pointer to `self` from void pointer:
            let mySelf = Unmanaged<ARManager>.fromOpaque(observer!).takeUnretainedValue()
            // Call instance method:
                        
            if numObservations == 0 {
                mySelf.triggerMatrixStreamCallback(observationList: [])
                return
            }

            var visibleMarkers : [ProcessedObservation] = [ProcessedObservation]()

            for i in 0 ..< numObservations {
                if let observation = trackableObservations?[Int(i)] {
                    if let processed = mySelf.processTrackableObservation(observation) {
                        if (processed.trackingStatusInfo != "NOT_OBSERVED" && processed.modelMatrix != "[]") {
                            if (processed.trackingStatus == "EXTENDED_TRACKED" && !mySelf.isExtendedTrackingEnabled) {
                                continue;
                            }
                            visibleMarkers.append(processed)
                        }
                    }
                }
            }
            mySelf.triggerMatrixStreamCallback(observationList: visibleMarkers)

        });
    }
    
    private func triggerMatrixStreamCallback(observationList: [ProcessedObservation]) {
        visibleMarkersCompletionHandler?(observationList)
    }
    
    func bridge(_ obj : ARManager) -> UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(Unmanaged.passUnretained(obj).toOpaque())
    }
    
    func bridge(_ ptr : UnsafeMutableRawPointer) -> ARManager? {
        return Unmanaged.fromOpaque(ptr).takeUnretainedValue()
    }
    
    func setCameraMatrixCompletionHandler(completionHandler: @escaping MarkerCompletionHandler) {
        cameraMatrixCompletionHandler = completionHandler
        print("set cameraMatrixCompletionHandler")
        
        // Uses callback pattern from http://www.perry.cz/clanky/swift.html
        // and https://stackoverflow.com/questions/33294620/how-to-cast-self-to-unsafemutablepointervoid-type-in-swift
        setCameraMatrixCallback(bridge(self), {(observer, matrixString) -> Void in
            // Extract pointer to `self` from void pointer:
            let mySelf = Unmanaged<ARManager>.fromOpaque(observer!).takeUnretainedValue()
            // Call instance method:
            if let _matString = matrixString {
                // TODO: BEN - also get tracking status and tracking status info
                mySelf.triggerCallback(cameraMatrix: String(cString: _matString))
            }
        });
    }
    
    func triggerCallback(cameraMatrix: String?) {
//        print("swift function callback for CameraMatrix");
//        print(cameraMatrix ?? "(no camera matrix provided)")
        
        var statusInfoString = "NORMAL"
        var statusString = "NORMAL"

        if let trackingStatusInfo = getDevicePoseStatusInfo() {
            if let sTrackingStatusInfo = String(utf8String: trackingStatusInfo) {
                statusInfoString = sTrackingStatusInfo
            }
        }
        
        if let trackingStatus = getDevicePoseStatus() {
            if let sTrackingStatus = String(utf8String: trackingStatus) {
                statusString = sTrackingStatus
            }
        }
        
        let markerData = ["name": "device",
                          "modelViewMatrix": cameraMatrix ?? "[]",
                          "trackingStatus": statusString,
                          "trackingStatusInfo": statusInfoString]
        cameraMatrixCompletionHandler?(markerData);
    }
    
    func getProjectionMatrix(completionHandler: @escaping MatrixStringCompletionHandler) {
        projectionMatrixCompletionHandler = completionHandler;
        
        // Uses callback pattern from http://www.perry.cz/clanky/swift.html
        // and https://stackoverflow.com/questions/33294620/how-to-cast-self-to-unsafemutablepointervoid-type-in-swift
        setProjectionMatrixCallback(bridge(self), {(observer, matrixString) -> Void in
            // Extract pointer to `self` from void pointer:
            let mySelf = Unmanaged<ARManager>.fromOpaque(observer!).takeUnretainedValue()
            // Call instance method:
            if let _matString = matrixString {
                // TODO: BEN - also get tracking status and tracking status info
                mySelf.triggerProjectionCallback(projectionMatrix: String(cString: _matString))
//                print("trigger projection callback")
            }
        });
    }
    
    func triggerProjectionCallback(projectionMatrix: String?) {
        if let _projectionMatrix = projectionMatrix {
            projectionMatrixCompletionHandler?(_projectionMatrix);
        }
    }
    
    func setGroundPlaneMatrixCompletionHandler(completionHandler: @escaping MarkerCompletionHandler) {
        groundPlaneMatrixCompletionHandler = completionHandler
        print("set groundPlaneMatrixCompletionHandler")
    }
    
    func stopGroundPlaneTracker() {
        print("TODO: implement stopGroundPlaneTracker")
    }
    
    func enableExtendedTracking() {
        isExtendedTrackingEnabled = true
    }
    
    func parseSize(sizeString: String?) -> Float? {
        guard let _string = sizeString else { return nil }
        let arr = _string.split(separator: " ")
        if arr.count < 1 { return nil }
        return Float(arr[0])
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        guard let targetName = attributeDict["name"] else { return }
        guard let targetPath = getFilePathForName(targetName) else { return }
        
        if (targetsAdded[targetName] ?? false) {
            print("already added target for \(targetName) ... skip")
            if let callback = targetCallbacks[targetPath] {
                callback(true) // don't return false otherwise userinterface will think target isn't here anymore
            }
            return
        }
        
        var success = false
        
        if elementName == "ImageTarget" {
            if targetPath.contains("target.jpg") {
                if let size = parseSize(sizeString: attributeDict["size"]) {
                    success = addImageTargetJPG(targetPath, targetName, size)
                }
            } else {
                success = addImageTarget(targetPath, targetName)
            }
        } else if elementName == "ObjectTarget" {
            success = addObjectTarget(targetPath, targetName)
        } else if elementName == "ModelTarget" {
            success = addModelTarget(targetPath, targetName)
        } else if elementName == "AreaTarget" {
            success = addAreaTarget(targetPath, targetName)
        }
        
        if success {
            targetsAdded[targetName] = true
        }
        if let callback = targetCallbacks[targetPath] {
            callback(success)
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        // unimportant
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // unimportant
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("parse failure error: ", parseError)
    }
    
    // MARK: - VideoRecordingSource
    
    func getVideoBackgroundPixels() -> [GLchar] {
        print("->start: cGetVideoBackgroundPixels")
        cGetVideoBackgroundPixels()
        print("<-done.: cGetVideoBackgroundPixels")
        return [];
    }
    
    func getCameraFrameImage() -> UnsafeMutablePointer<VuImageInfo>? {
        let info = cGetCameraFrameImage()
        return info;
    }
    
    func getCurrentARViewBoundsSize() -> CGSize {
        return CGSize.zero
    }
    
}
