//
//  WebServerManager.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/8/21.
//

import Foundation

class WebServerManager {
    
    // MARK: - Singleton
    static let shared = WebServerManager()
    
    // MARK: - Initialization
    
    private init() {
        let nodejsThread = Thread(target: self, selector: #selector(self.startNode), object: nil)
        nodejsThread.stackSize = 8 * 1024 * 1024;
        nodejsThread.start()
        print("Init nodejsThread");
    }
    
    @objc private func startNode() {
        print("NodeRunner.startEngine");
        let srcPath = Bundle.main.path(forResource: "vuforia-spatial-edge-server/server.js", ofType: "")
        let nodeArguments:[String?] = ["node", srcPath]
        NodeRunner.startEngine(withArguments: nodeArguments as [Any])
    }
    
    // MARK: - Public Functions

    func getServerURL() -> URL {
        return URL(string: "http://127.0.0.1:49368/")!
    }
}
