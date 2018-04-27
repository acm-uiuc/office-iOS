//
//  ACMAudioSessionController.swift
//  office
//
//  Created by Sujay Patwardhan on 4/20/18.
//  Copyright © 2018 acm. All rights reserved.
//

import Foundation
import AVFoundation

public protocol ACMAudioSessionDelegate: class {
    func acmAudioSession(_ acmAudioSession: ACMAudioSession, didReceiveVolumeEvent: Int)
}

public final class ACMAudioSession: NSObject {
    private weak var delegate: ACMAudioSessionDelegate?
    private var observation: NSKeyValueObservation?
    
    public init(delegate: ACMAudioSessionDelegate? = nil) {
        self.delegate = delegate
    }
    
    public func setUpVolumeListener() {
        listenForVolumeUpdate()
    }
    
    public func tearDownVolumeListener() {
        // TODO: removeObserver
    }

    func listenForVolumeUpdate(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
            
            observation = audioSession.observe(\AVAudioSession.outputVolume) { (foo, change) in
                if ACMApplicationController.shared.originalVolume == -1 {
                    ACMApplicationController.shared.originalVolume = Int(foo.outputVolume*100)
                }
                self.delegate?.acmAudioSession(self, didReceiveVolumeEvent: Int(foo.outputVolume*100))
            }
        } catch {
            print("failed to start observer")
        }
    }
}
