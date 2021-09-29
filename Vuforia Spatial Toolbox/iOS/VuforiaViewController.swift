/*===============================================================================
Copyright (c) 2020, PTC Inc. All rights reserved.
 
Vuforia is a trademark of PTC Inc., registered in the United States and other
countries.
===============================================================================*/

import UIKit

import Foundation


class VuforiaViewController: UIViewController {

    struct Constants {
        static let QUIT_ON_ERROR = Notification.Name("QuitOnError")
    }

    
    @IBOutlet var mVuforiaView: VuforiaView!
    var mTarget: Int32 = -1
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setToolbarHidden(true, animated: false)
        
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doFocus))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(singleTapRecognizer)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.returnToMenu))
        doubleTapRecognizer.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleTapRecognizer)
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        
        // we use the iOS notification to pause/resume the AR when the application goes to (or comes back from) background
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resume), name: UIApplication.didBecomeActiveNotification, object: nil)

        // register for notification that we will send when the user dismisses the error dialog
        NotificationCenter.default.addObserver(self, selector: #selector(returnToMenu), name: Constants.QUIT_ON_ERROR, object: nil)
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if (!self.isMetalSupported()) {
            
            let alert = UIAlertController(title: "Metal not supported", message: "Metal API is not supported on this device.", preferredStyle: UIAlertController.Style.alert)
            
            let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
                NotificationCenter.default.post(name: Constants.QUIT_ON_ERROR, object: nil)
            })
            
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let errorCallback: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<Int8>?) -> Void = {(observer, errorString) -> Void in
                let viewController = Unmanaged.fromOpaque(observer!).takeUnretainedValue() as VuforiaViewController
                viewController.presentError(error: errorString!)
            };
            
            let initDoneCallback: @convention(c) (UnsafeMutableRawPointer?) -> Void = {(observer) -> Void in
                let viewController = Unmanaged.fromOpaque(observer!).takeUnretainedValue() as VuforiaViewController
                DispatchQueue.main.async {
                    viewController.mVuforiaView.mVuforiaStarted = startAR()
                    viewController.hideLoadingAnimation()
                }
            }

            var initConfig: VuforiaInitConfig = VuforiaInitConfig()
            initConfig.classPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
            initConfig.errorCallback = errorCallback
            initConfig.initDoneCallback = initDoneCallback
            initConfig.vbRenderBackend = VuRenderVBBackendType(VU_RENDER_VB_BACKEND_METAL)
            
            initAR(initConfig, self.mTarget)
        }
        
        showLoadingAnimation()
    }


    override func viewWillDisappear(_ animated: Bool) {
        mVuforiaView.finish()
        stopAR()
        deinitAR()
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }

    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // Disable rotation animation
        UIView.setAnimationsEnabled(false)
    }

    
    @objc func pause() {
        stopAR()
    }
    
    
    @objc func resume() {
        startAR()
    }
    
    
    @objc func returnToMenu() {
        self.dismiss(animated: true)
    }
    
    
    @objc func doFocus() {
        // Call Vuforia to Focus
        cameraPerformAutoFocus()
        
        // After triggering an autofocus event,
        // we must restore the previous focus mode
        self.perform(#selector(self.restoreContinuousAutoFocus), with: nil, afterDelay: 2.0)
    }
    
    
    @objc func restoreContinuousAutoFocus() {
        cameraRestoreAutoFocus()
    }
    


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        stopAR()
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func isMetalSupported() -> Bool {
        var metalIsSupported = false
        
        let device = MTLCreateSystemDefaultDevice();
        if ((device) != nil) {
            metalIsSupported = true;
        }
        
        return metalIsSupported;
    }
    
    
    func presentError(error:UnsafePointer<Int8>) {
        let errorString = String(cString: error)
        DispatchQueue.main.async {
            
            let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
                NotificationCenter.default.post(name: Constants.QUIT_ON_ERROR, object: nil)
            })
            
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
        }
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
        loadingIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        
        mVuforiaView.addSubview(loadingIndicator)
        loadingIndicator.startAnimating()
    }
    
    
    func hideLoadingAnimation() {
        let loadingIndicator = self.mVuforiaView.viewWithTag(1)
        loadingIndicator?.removeFromSuperview()
    }
}
