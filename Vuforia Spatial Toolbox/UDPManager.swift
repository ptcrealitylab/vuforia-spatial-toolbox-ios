//
//  UDPManager.swift
//  vst-swift
//
//  Created by Ben Reynolds on 9/10/21.
//

import Foundation

typealias UDPMessageCompletionHandler = (String) -> ()

class UDPManager: NSObject, GCDAsyncUdpSocketDelegate {
    
    // MARK: - Singleton
    static let shared = UDPManager()
    
    var messageHandler:UDPMessageCompletionHandler?
    var udpSocket:GCDAsyncUdpSocket?

    let UDP_BROADCAST_HOST = "255.255.255.255"
    let UDP_PORT = UInt16(52316)
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        
        udpSocket = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: DispatchQueue.main)
        
        do {
            try udpSocket?.enableReusePort(true)
            try udpSocket?.bind(toPort: UDP_PORT)
            try udpSocket?.enableBroadcast(true)
            try udpSocket?.beginReceiving()
        } catch {
            print(error)
        }
    }
    
    // MARK: - Public Functions

    func setReceivedMessageCallback(completionHandler: @escaping UDPMessageCompletionHandler) {
        messageHandler = completionHandler
        print("set UDP Message Handler")
    }
    
    func sendUDPMessage(message: String) {
        if let data = message.data(using: .utf8) {
            udpSocket?.send(data, toHost: UDP_BROADCAST_HOST, port: UDP_PORT, withTimeout: -1, tag: 1)
        }
    }
    
    // MARK: - Protocol Implementation
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        print("Successfully connected UDP socket to address \(address)")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("Could not connect UDP socket: \(error.debugDescription)")
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        
        if let dataString = String.init(data: data, encoding: .utf8) {
            if let _messageHandler = messageHandler {
                _messageHandler(dataString)
            }
        }
    }
}
