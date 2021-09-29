//
//  REWebView.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/7/21.
//

import Foundation
import UIKit
import WebKit

protocol WebViewDelegate {
    func handleAPI(_ test: String)
}

class REWebView: WKWebView {
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(delegateScript: WKScriptMessageHandler, delegateNavigation: WKNavigationDelegate, delegateUI: WKUIDelegate) {
        // make it fullscreen
//        let frame: CGRect = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        
        // create the configuration
        let userContentController = WKUserContentController.init()
//        userContentController.addScriptMessageHandler(T##scriptMessageHandlerWithReply: WKScriptMessageHandlerWithReply##WKScriptMessageHandlerWithReply, contentWorld: T##WKContentWorld, name: "realityEditor")
        
        userContentController.add(delegateScript, contentWorld: WKContentWorld.page, name: "realityEditor")
//        userContentController.addScriptMessageHandler(delegateScript, contentWorld: WKContentWorld.defaultClient, name: "realityEditor")
        print("added scriptMessageHandler")
        
        let configuration = WKWebViewConfiguration.init()
        configuration.userContentController = userContentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        self.init(frame: UIScreen.main.bounds, configuration: configuration)
        print("initialized the webView")

        // set delegate
//        scriptMessageHandler = delegateScript
        navigationDelegate = delegateNavigation
        uiDelegate = delegateUI
        
        // make it transparent and configure settings
        isOpaque = false
        backgroundColor = UIColor.clear
        allowsLinkPreview = false
        allowsBackForwardNavigationGestures = false
        window?.makeKeyAndVisible()

        // make it un-scrollable
        scrollView.isScrollEnabled = false
        scrollView.bounces = false
        
        // TODO: implement allowDisplayingKeyboardWithoutUserAction

//        loadInterfaceFromURL(urlString: "http://192.168.0.12:8081")
        
//        initWebServer()
    }
    
//    func initWebServer() {
//        print(WebServerManager.shared.getServerURL()) // this will force it to init
//    }
    
    func loadInterfaceFromLocalServer() {
        print("loadInterfaceFromLocalServer");
        URLCache.shared.removeAllCachedResponses()
        let serverURL = WebServerManager.shared.getServerURL()
        print(serverURL)
        load(URLRequest.init(url: serverURL, cachePolicy: NSURLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10.0))
    }
    
    func loadInterfaceFromURL(urlString: inout String) {
        if (urlString.count == 0) {
            self.loadInterfaceFromLocalServer()
            return
        }
        if (!urlString.contains("http://") && !urlString.contains("https://")) {
            urlString = "http://" + urlString;
        }
        urlString = urlString.replacingOccurrences(of: "\"", with: "") // remove quotes that may have been added during storage encoding
        URLCache.shared.removeAllCachedResponses()
        clearCache()
        guard let url = URL.init(string: urlString) else {
            return
        }
        load(URLRequest.init(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0))
    }
    
    func clearCache() {
        let dataTypes: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache];
        WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: Date(timeIntervalSince1970: 0)) {
            print("clearCache completed")
        }
    }
    
    override var safeAreaInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func runJavaScriptFromString(script: String) {
        var sanitizedScript = script.replacingOccurrences(of: "\n", with: "")
        sanitizedScript = script.replacingOccurrences(of: "\r", with: "")
        
        DispatchQueue.main.async {
            self.evaluateJavaScript(sanitizedScript, completionHandler: nil)
        }
    }
}

