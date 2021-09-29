//
//  DeviceStateManager.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/21/21.
//

import Foundation
import UIKit

typealias CompletionHandlerWithString = (String) -> ()

class DeviceStateManager: NSObject {
    
    // MARK: - Singleton
    static let shared = DeviceStateManager()
    
    // MARK: - Initialization
    
    var orientationCompletionHandler: CompletionHandlerWithString?
    var lifeCycleCompletionHandler: CompletionHandlerWithString?
    
    var viewToRotate: UIView?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Orientation Events

    func enableOrientationChanges(completionHandler: @escaping CompletionHandlerWithString) {
        orientationCompletionHandler = completionHandler
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(notification:)), name: UIDevice.orientationDidChangeNotification, object: UIDevice.current)
    }
    
    @objc func orientationChanged(notification: Notification) {
        if let device = notification.object as? UIDevice {
            updateOrientation(device.orientation)
        }
    }
    
    func updateOrientation(_ orientation: UIDeviceOrientation) {
        let orientationString = deviceOrientationToString(orientation)
        
        if orientationString == "landscapeLeft" {
            rotateView(upsideDown: true)
        } else if orientationString == "landscapeRight" {
            rotateView(upsideDown: false)
        }
        
        orientationCompletionHandler?(orientationString)
    }
    
    func deviceOrientationToString(_ orientation: UIDeviceOrientation) -> String {
        var str = "unknown"
        
        switch orientation {
        case UIDeviceOrientation.landscapeLeft:
            str = "landscapeLeft"
            break
        case UIDeviceOrientation.landscapeRight:
            str = "landscapeRight"
            break
        case UIDeviceOrientation.portrait:
            str = "portrait"
            break
        case UIDeviceOrientation.portraitUpsideDown:
            str = "portraitUpsideDown"
            break
        case UIDeviceOrientation.unknown:
            break
        default:
            break
        }
        
        return str
    }
    
    func rotateView(upsideDown: Bool) {
        guard let _view = viewToRotate else { return } // assign a viewToRotate from parent view controller
        
        if upsideDown {
            _view.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi)
        } else {
            _view.transform = CGAffineTransform.init(rotationAngle: 0)
        }
    }
    
    // MARK: - Life-Cycle Events
    
    func subscribeToAppLifeCycleEvents(completionHandler: @escaping CompletionHandlerWithString) {
        lifeCycleCompletionHandler = completionHandler
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
        
    }
    
    @objc func appDidBecomeActive(notification: Notification) {
        sendLifeCycleEvent("appDidBecomeActive")
    }
    
    @objc func appWillResignActive(notification: Notification) {
        sendLifeCycleEvent("appWillResignActive")
    }
    
    @objc func appDidEnterBackground(notification: Notification) {
        sendLifeCycleEvent("appDidEnterBackground")
    }
    
    @objc func appWillEnterForeground(notification: Notification) {
        sendLifeCycleEvent("appWillEnterForeground")
    }
    
    @objc func appWillTerminate(notification: Notification) {
        sendLifeCycleEvent("appWillTerminate")
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        
    }
    
    func sendLifeCycleEvent(_ eventName: String) {
        lifeCycleCompletionHandler?(eventName)
    }
}
