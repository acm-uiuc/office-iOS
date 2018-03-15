//
//  ACMConcertPlayerViewController.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import UIKit
import SocketIO
import MarqueeLabel

final class ACMConcertPlayerViewController: UIViewController {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var infoLabel: MarqueeLabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var volumeSilder: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!

    let socketManger = SocketManager(socketURL: URL(string: "http://172.20.10.9:5000")!)
    let jsonDecoder = JSONDecoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSocket()
        infoLabel.animationDelay = 2
        infoLabel.trailingBuffer = 24
        infoLabel.fadeLength = 16

        volumeSilder.minimumValue = 0
        volumeSilder.maximumValue = 100
        volumeSilder.minimumValueImage = #imageLiteral(resourceName: "volumeLow")
        volumeSilder.maximumValueImage = #imageLiteral(resourceName: "volumeHigh")
        volumeSilder.tintColor = UIColor.gray

        progressSlider.setThumbImage(UIImage(), for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSocket()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setupSocket),
            name: .UIApplicationDidBecomeActive, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(teardownSocket),
            name: .UIApplicationWillResignActive, object: nil
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillResignActive, object: nil)
        teardownSocket()
    }

    // MARK: Socket Init
    func configureSocket() {
        socketManger.defaultSocket.on("connected", callback: handleUpdate)
        socketManger.defaultSocket.on("volume_changed", callback: handleUpdate)
        socketManger.defaultSocket.on("paused", callback: handleUpdate)
    }

    @objc func setupSocket() {
        socketManger.connect()
    }

    @objc func teardownSocket() {
        socketManger.disconnect()
    }

    // MARK: Actions
    @IBAction func button() {
        socketManger.defaultSocket.emit("pause")
    }

    @IBAction func volumeSlider() {
        let volume = Int(volumeSilder.value)
        socketManger.defaultSocket.emit("volume", volume)
    }

    // MARK: Handlers
    func handleUpdate(dataArray: [Any], ack: SocketAckEmitter) {
        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertStatus.self, from: jsonData) else { return }

        DispatchQueue.main.async {
            self.updateUI(with: status)
        }
    }
    
    func updateUI(with status: ACMConcertStatus) {
        if let currentTrack = status.currentTrack {
            infoLabel.text = currentTrack
        }

        if let volume = status.volume {
            volumeSilder.value = Float(volume)
        }

        if let isPlaying = status.isPlaying,
            let audioStatus = status.audioStatus {
            let displayIsPlaying = isPlaying && (audioStatus == "State.Playing" || audioStatus == "State.Opening")
            print(displayIsPlaying)
            let image = displayIsPlaying ? #imageLiteral(resourceName: "pause") : #imageLiteral(resourceName: "play")
            playPauseButton.setImage(image, for: .normal)
        }
    }
}
