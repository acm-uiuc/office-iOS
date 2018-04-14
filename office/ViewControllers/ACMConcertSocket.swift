//
//  ACMConcertSocket.swift
//  office
//
//  Created by Sujay Patwardhan on 4/12/18.
//  Copyright © 2018 acm. All rights reserved.
//

import Foundation
import SocketIO

public protocol ACMConcertSocketDelegate: class {
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceivePlayStateUpdate: Bool)
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveVolumeUpdate: Int)
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveProgressUpdate progress: Int, didReceiveDurationUpdate duration: Int)
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveNewArtwork: URL?)
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveInfoLabel: String?)
}

public final class ACMConcertSocket {
    weak private var delegate: ACMConcertSocketDelegate?
    
    private let socketManager = SocketManager(socketURL: URL(string: "https://concert.acm.illinois.edu")!)
    
    public init(delegate: ACMConcertSocketDelegate? = nil) {
        self.delegate = delegate
        configureSocket()
    }
    
    let jsonDecoder = JSONDecoder()
    
    // MARK: Socket Init
    func configureSocket() {
        socketManager.defaultSocket.on("connected",      callback: handleConnection)
        socketManager.defaultSocket.on("heartbeat",      callback: handleConnection)
        socketManager.defaultSocket.on("skipped",        callback: handleConnection)
        socketManager.defaultSocket.on("volume_changed", callback: handleVolume)
        socketManager.defaultSocket.on("paused",         callback: handlePause)
        socketManager.defaultSocket.on("played",         callback: handleConnection)
        socketManager.defaultSocket.on("stopped",        callback: handlePause)
    }
    
    @objc public func setupSocket() {
        socketManager.connect()
    }
    
    @objc public func teardownSocket() {
        socketManager.disconnect()
    }
    
    func sendVolumeChanged(with newVolume: Int) {
        socketManager.defaultSocket.emit("volume", newVolume)
        print("emitting")
    }
    
    // MARK: Handlers
    func handleConnection(dataArray: [Any], ack: SocketAckEmitter) {
        print("handle connection a")
        
        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertOnConnect.self, from: jsonData) else { return }
        
        print("handle connection b")
        
        let isPlaying = status.isPlaying,
        audioStatus = status.audioStatus
        let displayIsPlaying = isPlaying && (audioStatus == "State.Playing" || audioStatus == "State.Opening")
        
        let url = URL.init(string: "http://concert.acm.illinois.edu/" + status.thumbnail)
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceiveProgressUpdate: status.currentTime/1000, didReceiveDurationUpdate: status.duration/1000)
            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceiveNewArtwork: url)
            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceivePlayStateUpdate: displayIsPlaying)
            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceiveVolumeUpdate: status.volume)
            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceiveInfoLabel: status.currentTrack)
        }
    }
    
    func handleVolume(dataArray: [Any], ack: SocketAckEmitter) {
        print("handle volume a")
        
        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertVolume.self, from: jsonData) else { return }
        
        print("handle volume b")
        
        let volume = status.volume
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceiveVolumeUpdate: volume)
            
        }
    }
    
    func handlePause(dataArray: [Any], ack: SocketAckEmitter) {
        print("handle pause a")
        
        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertOnPause.self, from: jsonData) else { return }
        
        print("handle pause b")
        
        let isPlaying = status.isPlaying,
        audioStatus = status.audioStatus
        let displayIsPlaying = isPlaying && (audioStatus == "State.Playing" || audioStatus == "State.Opening")
        print(displayIsPlaying)
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceivePlayStateUpdate: displayIsPlaying)
        }
    }
    
//    func handlePlay(dataArray: [Any], ack: SocketAckEmitter) {
//        print("handle play a")
//
//        guard let jsonString = dataArray.first as? String,
//            let jsonData = jsonString.data(using: .utf8),
//            let status = try? jsonDecoder.decode(ACMConcertOnPlay.self, from: jsonData) else { return }
//
//        print("handle play b")
//
//        let isPlaying = status.isPlaying,
//        audioStatus = status.audioStatus
//        let displayIsPlaying = isPlaying && (audioStatus == "State.Playing" || audioStatus == "State.Opening")
//        let url = URL.init(string: "http://concert.acm.illinois.edu/" + status.thumbnail)
//
//        DispatchQueue.main.async { [weak self] in
//            guard let strongSelf = self else { return }
//            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceivePlayStateUpdate: displayIsPlaying)
//            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceiveProgressUpdate: status.currentTime/1000, didReceiveDurationUpdate: status.duration/1000)
//            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceiveInfoLabel: status.currentTrack)
//            strongSelf.delegate?.acmConcertSocket(strongSelf, didReceiveNewArtwork: url)
//        }
//    }
}
