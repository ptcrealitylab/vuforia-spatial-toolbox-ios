//
//  MainViewController.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/7/21.
//

import UIKit
import WebKit

class MainViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, JavaScriptCallbackDelegate {

    var webView : REWebView?
    var vuforiaView : VuforiaView?
    var kvoToken: NSKeyValueObservation?
    var doneLoading = false
    
    struct Constants {
        static let QUIT_ON_ERROR = Notification.Name("QuitOnError")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.navigationController?.setToolbarHidden(true, animated: false)
        view.backgroundColor = UIColor.clear
        
        // we use the iOS notification to pause/resume the AR when the application goes to (or comes back from) background
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resume), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // add first so it goes in the back
        vuforiaView = VuforiaView(frame: UIScreen.main.bounds)
        if let _vuforiaView = vuforiaView {
            view.addSubview(_vuforiaView)
            setupVuforiaView()
        }
        
        webView = REWebView(delegateScript: self, delegateNavigation: self, delegateUI: self)
        if let _webView = webView {
            // NSKeyValueObservingOptions(rawValue: (NSKeyValueObservingOptions.old.rawValue | NSKeyValueObservingOptions.new.rawValue)) ?? default
//            _webView.addObserver(self, forKeyPath: "loading", options: [.old, .new], context: nil)
                        
            kvoToken = _webView.observe(\.isLoading, options: .new, changeHandler: { (thisWebView, thisChange) in
                guard let isLoading = thisChange.newValue else { return }
                print("New isLoading is: \(isLoading)")
                
                if (!isLoading && !self.doneLoading) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                       // Excecute after 3 seconds
                        _webView.loadInterfaceFromLocalServer()
                    }
                }
            })
            
            // start loading one time. it will repeat every ~3 seconds as needed
            _webView.loadInterfaceFromLocalServer()

            view.addSubview(_webView)
        }
        
        JavaScriptAPIHandler.shared.delegate = self
        
//        ARManager.shared.containingViewController = self
        
        VideoRecordingManager.shared.recordingDelegate = ARManager.shared as VideoRecordingSource
        
        DeviceStateManager.shared.viewToRotate = webView
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        vuforiaView?.finish()
        ARManager.shared.stop()
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    private func setupVuforiaView() {
        if (!self.isMetalSupported()) {
            
            let alert = UIAlertController(title: "Metal not supported", message: "Metal API is not supported on this device.", preferredStyle: UIAlertController.Style.alert)
            
            let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in
                NotificationCenter.default.post(name: Constants.QUIT_ON_ERROR, object: nil)
            })
            
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        ARManager.shared.setupVuforiaView(vuforiaView: self.vuforiaView)
    }
    
    @objc func pause() {
        ARManager.shared.pause();
    }
    
    @objc func resume() {
        ARManager.shared.resume()
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

    private func handleCustomRequest(messageBody: [String:Any]) {
        if let functionName = messageBody["functionName"] as? String {
            let arguments = messageBody["arguments"] as? [String:Any]
            let callback = messageBody["callback"] as? String
            
            // this function needs access to the main view controller's private member
            if (functionName == "loadNewUI") {
                if let args = arguments {
                    if var reloadURL = args["reloadURL"] as? String {
                        self.webView?.loadInterfaceFromURL(urlString: &reloadURL)
                    }
                }
            } else if (functionName == "clearCache") {
                self.webView?.clearCache()
            } else {
                JavaScriptAPIHandler.shared.processRequest(functionName: functionName, arguments: arguments, callback: callback)
            }
            
        } else {
            print("request has no functionName - ignore")
            return
        }
    }
    
    // MARK: - WKScriptMessageHandler Protocol Implementation
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String:Any] else {
            print("error parsing webkit script")
            return
        }
        handleCustomRequest(messageBody: body)
    }

    // MARK: - WKNavigaionDelegate Protocol Implementaion

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if (navigationAction.navigationType == WKNavigationType.linkActivated) {
            if let thisURL = navigationAction.request.url {
                if let resourceSpecifier = (thisURL as NSURL).resourceSpecifier {
                    if (resourceSpecifier.contains("spatialtoolbox.vuforia.com") || resourceSpecifier.contains("github.com")) {
                        if (UIApplication.shared.canOpenURL(thisURL)) {
                            UIApplication.shared.open(thisURL, options: [:], completionHandler: nil)
                            decisionHandler(WKNavigationActionPolicy.cancel)
                        }
                    } else {
                        decisionHandler(WKNavigationActionPolicy.allow)
                    }
                }
            }
        } else {
            decisionHandler(WKNavigationActionPolicy.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView didFinish navigation")
        doneLoading = true
    }
    
    // MARK: - JavaScript Callback Delegate
    
    func callJavaScriptCallback(callback: String?, arguments: [String]) {
        if var callbackString = callback {
            for (i, arg) in arguments.enumerated() {
                callbackString = callbackString.replacingOccurrences(of: "__ARG\(i+1)__", with: arg)
            }
            self.webView?.runJavaScriptFromString(script: callbackString)
            
            // for debugging specific APIs
//            if callbackString.contains("receiveMatricesFromAR") { //onMarkerAdded") {
//                print(">> \(callbackString)")
//            }
        }
    }
}
