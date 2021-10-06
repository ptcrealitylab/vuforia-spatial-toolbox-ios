//
//  VideoRecordingManager.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/23/21.
//

import Foundation
import UIKit
import AVFoundation
import VideoToolbox

protocol VideoRecordingSource {
    var isRecording: Bool { get set }
    
    func getVideoBackgroundPixels() -> [GLchar]
    func getCameraFrameImage() -> UnsafeMutablePointer<VuImageInfo>?
    func getCurrentARViewBoundsSize() -> CGSize

}

extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)

        guard let cgImage = cgImage else {
            return nil
        }

        self.init(cgImage: cgImage)
    }
}

class VideoRecordingManager {
    
    // MARK: - Singleton
    static let shared = VideoRecordingManager()
    
    // MARK: - Initialization
    var assetWriter: AVAssetWriter?
    var assetWriterInput: AVAssetWriterInput?
    var pixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    
    var isRecording = false
    var recordingStartTime: CFTimeInterval?
    var firstFrameOffset: CFTimeInterval?
//    var updateTimer: Timer?
    
    var displayLink: CADisplayLink?
    
    var objectIP: String?
    var objectID: String?
    var objectPort: String?
    
    var recordingDelegate: VideoRecordingSource?
    
    private init() {
        print("Init FileManager");
    }
    
    func startRecording(objectKey: String, ip: String, port: String) {
        print("startRecording!")
//        let videoOutputSize = CGSize(width: 640, height: 480)
        let videoOutputSize = CGSize(width: 1920, height: 1080)
        let frameRate = 30
        
        if isRecording {
            print("can't record until first finishes ... already recording")
        }
        
        let videoId = "\(Int.random(in: 1 ..< 10000000)).mp4"
        let videoOutPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(videoId) //else { return }
        
        print("videoOutPath: \(videoOutPath)")
        
        do {
            assetWriter = try AVAssetWriter(outputURL: videoOutPath, fileType: .mp4)
        } catch {
            print(error)
            return
        }
        
        guard let _writer = assetWriter else { return }
        
        _writer.shouldOptimizeForNetworkUse = true
        _writer.movieTimeScale = 60

        let compressionProperties: [String: Any] = [
            AVVideoProfileLevelKey:             AVVideoProfileLevelH264BaselineAutoLevel,
            AVVideoH264EntropyModeKey:          AVVideoH264EntropyModeCABAC,
            AVVideoAverageBitRateKey:           videoOutputSize.width * videoOutputSize.height * 11.4,
            AVVideoMaxKeyFrameIntervalKey:      60,
            AVVideoAllowFrameReorderingKey:     false
        ]
        
        let videoSettings: [String: Any] = [
            AVVideoCompressionPropertiesKey:    compressionProperties,
            AVVideoCodecKey:                   AVVideoCodecType.h264,
            AVVideoWidthKey:                   videoOutputSize.width,
            AVVideoHeightKey:                  videoOutputSize.height
        ]

        // creates the asset writer input to handle adding the video frames with the specified compression properties

        assetWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        guard let _input = assetWriterInput else { return }

        _input.mediaTimeScale = 60
        _input.expectsMediaDataInRealTime = true
        _input.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        
        // the pixel buffer input is used to manually write frames into the video using pixel buffers, rather than letting something like ReplayKit add the frames
        
        let sourcePixelBufferAttributes: [String: Any] = [
//            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32ARGB)
            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_24RGB)
        ]
        pixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: _input, sourcePixelBufferAttributes: sourcePixelBufferAttributes)
        
        _writer.add(_input)

        recordingStartTime = CACurrentMediaTime() // frame timestamps are relative to when the video starts
        firstFrameOffset = -1 // the first frame might not get written immediately, so this offsets all the frame times by the difference (-1 means unset)
        
        _writer.startWriting()
        _writer.startSession(atSourceTime: CMTime.zero)
        
        isRecording = true
        
        // notify the delegate class that recording started, which is responsible for providing pixel buffers each frame via getVideoBackgroundPixels
        // this makes it continually refresh its pixel buffer until recordingStopped() is called
        recordingDelegate?.isRecording = true
        
        // this will trigger at our specified FPS
//        updateTimer = Timer(timeInterval: (1.0 / Double(frameRate)), target: self, selector: #selector(writeFrame), userInfo: nil, repeats: true)
//        RunLoop.current.add(updateTimer, forMode: .common)
        
        // this will trigger each time the screen updates (60 or 120 fps)
        displayLink = CADisplayLink(target: self, selector: #selector(writeFrame))
        displayLink?.add(to: .current, forMode: .default)
        
        // save object id, ip, port for when video finishes writing
        objectIP = ip;
        objectID = objectKey;
        objectPort = port;
    }
    
    @objc func writeFrame() {
        if !isRecording {
            return
        }
        
        if firstFrameOffset == nil {
            firstFrameOffset = CACurrentMediaTime() - (recordingStartTime ?? CACurrentMediaTime())
        }
        
        guard let offset = firstFrameOffset,
              let startTime = recordingStartTime,
//              let _writer = assetWriter,
              let _input = assetWriterInput else { return }
        
        let frameTime = CACurrentMediaTime() - startTime - offset
        
        if !_input.isReadyForMoreMediaData {
            print("_input not ready \(frameTime)")
            return
        }

        guard let cameraImageInfoPointer = recordingDelegate?.getCameraFrameImage() else {
            print("error getting cameraImageInfo")
            cVuforiaCleanupStateMemory()
            return
        }
        
//        print("got cameraImageInfoPointer")
//        print(cameraImageInfoPointer)

        let cameraImageInfo = cameraImageInfoPointer.pointee
//        print(cameraImageInfo)
        
        let pixels: UnsafeMutableRawPointer = UnsafeMutableRawPointer(mutating: cameraImageInfo.buffer)

        print(pixelBufferInput?.pixelBufferPool)
        
        guard (pixelBufferInput?.pixelBufferPool) != nil else {
            cVuforiaCleanupStateMemory()
            return
        }

        var pixelBuffer: CVPixelBuffer? = nil
        
        // Define a function to call when the pixel buffer is freed.
//        let releaseCallback: CVPixelBufferReleaseBytesCallback = { releaseRefCon, baseAddress in
//            print("CVPixelBufferReleaseBytesCallback (1)")
//
//            guard let baseAddress = baseAddress else { return }
//            free(UnsafeMutableRawPointer(mutating: baseAddress))
//            // Perform additional cleanup as needed.
//        }

        print("||--- create buffer")
//        let status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(cameraImageInfo.width), Int(cameraImageInfo.height), kCVPixelFormatType_24RGB, pixels, Int(cameraImageInfo.stride), { releaseContext, baseAddress in
//            print("CVPixelBufferReleaseBytesCallback (1)")
//        }, nil, nil, &pixelBuffer)
        
        let status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(cameraImageInfo.width), Int(cameraImageInfo.height), kCVPixelFormatType_24RGB, pixels, Int(cameraImageInfo.stride), nil, nil, nil, &pixelBuffer)

        if status != kCVReturnSuccess {
            print("could not get pixel buffer from asset writer input; dropping frame...")
            cVuforiaCleanupStateMemory()
            return
        }
        
        print("--- buffer created ---||")
        
        let presentationTime = CMTimeMakeWithSeconds(frameTime, preferredTimescale: 240)
        print(presentationTime.seconds)
        
        if let _pixelBuffer = pixelBuffer {
//            if CVPixelBufferLockBaseAddress(_pixelBuffer, CVPixelBufferLockFlags.readOnly) != kCVReturnSuccess {
//                print("error locking base address of pixel buffer")
//                return
//            }
            if let _pixelBufferInput = pixelBufferInput {
                print(">>> append buffer")
                _pixelBufferInput.append(_pixelBuffer, withPresentationTime: presentationTime)
                print("... buffer appended")
                
                cVuforiaCleanupStateMemory()
            }
//            CVPixelBufferUnlockBaseAddress(_pixelBuffer, .readOnly)
        }
        
//        if let _pixelBuffer = pixelBuffer {
//            if CVPixelBufferLockBaseAddress(_pixelBuffer, CVPixelBufferLockFlags.readOnly) != kCVReturnSuccess {
//                print("error locking base address of pixel buffer")
//                return
//            }
//
//            guard let sourceData = CVPixelBufferGetBaseAddress(_pixelBuffer) else {
//                print("could not get pixel buffer base address")
//                CVPixelBufferUnlockBaseAddress(_pixelBuffer, .readOnly)
//                return
//            }
//
//            let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(_pixelBuffer)
//            let sourceWidth = CVPixelBufferGetWidth(_pixelBuffer)
//            let sourceHeight = CVPixelBufferGetHeight(_pixelBuffer)
////            let offset = 0
//
//            guard let scaledData = malloc(sourceHeight * sourceBytesPerRow) else {
//                print("error: out of memory")
//                CVPixelBufferUnlockBaseAddress(_pixelBuffer, .readOnly)
//                return
//            }
//
//            let pixelFormatType = CVPixelBufferGetPixelFormatType(_pixelBuffer)
//            var outputPixelBuffer: CVPixelBuffer? = nil
//
////            let status = CVPixelBufferCreateWithBytes(nil, sourceWidth, sourceHeight, pixelFormatType, scaledData, sourceBytesPerRow, nil, nil, nil, &outputPixelBuffer)
//            let status = CVPixelBufferCreateWithBytes(nil, sourceWidth, sourceHeight, pixelFormatType, sourceData, sourceBytesPerRow,
//              { releaseContext, baseAddress in
//                  print("CVPixelBufferReleaseBytesCallback (2)")
//              }, nil, nil, &outputPixelBuffer)
//
//            CVPixelBufferUnlockBaseAddress(_pixelBuffer, .readOnly)
//
//            if status != kCVReturnSuccess {
//                print("error: could not create new pixel buffer")
//                free(scaledData)
//                return
//            }
//
//            if let _outputBuffer = outputPixelBuffer {
//                if let _pixelBufferInput = pixelBufferInput {
//                    _pixelBufferInput.append(_outputBuffer, withPresentationTime: presentationTime)
//                }
//            }
            
//            let image = CIImage(cvPixelBuffer: pixelBuffer)

//            if let _pixelBufferInput = pixelBufferInput {
////                CVPixelBufferLockBaseAddress(_pixelBuffer, CVPixelBufferLockFlags.readOnly)
//
//                _pixelBufferInput.append(_pixelBuffer, withPresentationTime: presentationTime)
////                print("appended _pixelBuffer to pixelBufferInput")
//
////                CVPixelBufferUnlockBaseAddress(_pixelBuffer, .readOnly)
//            }
//        }
        
        print("writeFrame ended")
    }
    
    func pixelBufferReleaseCallback(releaseRefCon: UnsafeMutableRawPointer?, baseAddress: UnsafeMutableRawPointer?) {
        if baseAddress != nil {
            free(baseAddress)
        }
    }
    
    func stopRecording(videoID: String) {
        if !isRecording {
            return
        }
        
        guard let _writer = assetWriter,
              let _input = assetWriterInput else { return }
        
        isRecording = false
        recordingDelegate?.isRecording = false
        displayLink?.invalidate()
        _input.markAsFinished()
        _writer.finishWriting { [self] in
            if let _ip = objectIP,
               let _id = objectID,
               let _port = objectPort {
                
                if let urlEndpoint = URL(string: "http://\(_ip):\(_port)/object/\(_id)/video/\(videoID)") {
                    FileDownloadManager.shared.uploadVideoFileFromPath(_writer.outputURL, toURL: urlEndpoint)
                } else {
                    print("error creating urlEndpoint for video.. http://\(_ip):\(_port)/object/\(_id)/video/\(videoID)")
                }
            }
            
            assetWriterInput = nil
            assetWriter = nil
            pixelBufferInput = nil
        }
    }
    
    func getScreenshot() -> String? {
        guard let cameraImageInfoPointer = recordingDelegate?.getCameraFrameImage() else {
            print("error getting cameraImageInfo")
            cVuforiaCleanupStateMemory()
            return nil
        }
        
        let cameraImageInfo = cameraImageInfoPointer.pointee
        print(cameraImageInfo)
        
        let pixels: UnsafeMutableRawPointer = UnsafeMutableRawPointer(mutating: cameraImageInfo.buffer)

        var pixelBuffer: CVPixelBuffer? = nil
        
        let status = CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(cameraImageInfo.width), Int(cameraImageInfo.height), kCVPixelFormatType_24RGB, pixels, Int(cameraImageInfo.stride), nil, nil, nil, &pixelBuffer)

        if status != kCVReturnSuccess {
            print("could not get pixel buffer from asset writer input; dropping frame...")
            cVuforiaCleanupStateMemory()
            return nil
        }
                
        if let _pixelBuffer = pixelBuffer {
            CVPixelBufferLockBaseAddress(_pixelBuffer, .readOnly)

            let image = CIImage(cvPixelBuffer: _pixelBuffer)
            print(image)
            
            let tempContext = CIContext.init(options: nil)
            if let videoImage = tempContext.createCGImage(image, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(_pixelBuffer), height: CVPixelBufferGetHeight(_pixelBuffer))) {
                let newUiImage = UIImage(cgImage: videoImage, scale: 0.5, orientation: .down)
                
                let imageData = newUiImage.jpegData(compressionQuality: 0.7)
                let encodedString = imageData?.base64EncodedString(options: .endLineWithCarriageReturn)
                
                CVPixelBufferUnlockBaseAddress(_pixelBuffer, .readOnly)

                cVuforiaCleanupStateMemory()
                
                return encodedString
            }
            
            CVPixelBufferUnlockBaseAddress(_pixelBuffer, .readOnly)
        }

        cVuforiaCleanupStateMemory()
        return nil
    }
    
//    private func imageWith(newSize: CGSize) -> UIImage {
//        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
//            draw(in: CGRect(origin: .zero, size: newSize))
//        }
//
//        return image.withRenderingMode(renderingMode)
//    }
    
    func imageWithImage(_ image: UIImage?, scaledToSize newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image?.draw(in: CGRect(x: 0.0, y: 0.0, width: newSize.width, height: newSize.height))
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
