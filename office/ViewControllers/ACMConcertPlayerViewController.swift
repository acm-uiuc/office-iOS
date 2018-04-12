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
import ChameleonFramework
import YXWaveView

final class ACMConcertPlayerViewController: UIViewController {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artworkImageContainerView: UIView!
    @IBOutlet weak var backgroundArtworkImageView: UIImageView!


    @IBOutlet weak var waveView: YXWaveView!


    @IBOutlet weak var infoLabel: MarqueeLabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var viewQueueButton: UIButton!

    let socketManager = SocketManager(socketURL: URL(string: "http://concert.acm.illinois.edu")!)
    let jsonDecoder = JSONDecoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSocket()

        waveView.realWaveColor = UIColor.white.withAlphaComponent(1)
        waveView.maskWaveColor = UIColor.white.withAlphaComponent(0.3)
        waveView.waveSpeed = 1.3
        waveView.waveHeight = 12
        waveView.waveCurvature = 1.2
        waveView.start()

        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.cornerRadius = 20.0
        artworkImageView.layer.masksToBounds = true

        artworkImageContainerView.layer.shadowColor = UIColor.black.cgColor
        artworkImageContainerView.layer.shadowOffset = .zero
        artworkImageContainerView.layer.shadowRadius = 12.0
        artworkImageContainerView.layer.shadowOpacity = 0.6
        artworkImageContainerView.layer.masksToBounds = false
        artworkImageContainerView.layer.shadowPath = UIBezierPath(roundedRect: artworkImageView.bounds, cornerRadius: artworkImageView.layer.cornerRadius).cgPath

        infoLabel.animationDelay = 2
        infoLabel.trailingBuffer = 24
        infoLabel.fadeLength = 16

        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 100
        volumeSlider.minimumValueImage = #imageLiteral(resourceName: "volumeLow")
        volumeSlider.maximumValueImage = #imageLiteral(resourceName: "volumeHigh")
        volumeSlider.tintColor = UIColor.gray
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
        socketManager.defaultSocket.on("connected",      callback: handleConnection)
        socketManager.defaultSocket.on("heartbeat",      callback: handleConnection)
        socketManager.defaultSocket.on("skipped",        callback: handleConnection)
        socketManager.defaultSocket.on("volume_changed", callback: handleVolume)
        socketManager.defaultSocket.on("paused",         callback: handlePause)
        socketManager.defaultSocket.on("played",         callback: handlePlay)
    }

    @objc func setupSocket() {
        socketManager.connect()
    }

    @objc func teardownSocket() {
        socketManager.disconnect()
    }

    // MARK: Actions
    @IBAction func button() {
        socketManager.defaultSocket.emit("pause")
    }

    @IBAction func didChangeVolume() {
        let volume = Int(volumeSlider.value)
        socketManager.defaultSocket.emit("volume", volume)
    }

    // MARK: Handlers
    func handleConnection(dataArray: [Any], ack: SocketAckEmitter) {
        print("handle connection a")

        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertOnConnect.self, from: jsonData) else { return }

        print("handle connection b")

        DispatchQueue.main.async { [weak self] in
            self?.updateVolume(with: status.volume)
            self?.updateArtwork(with: status.thumbnail)
            self?.updatePlayPause(with: status.isPlaying)
            self?.updateInfoLabel(with: status.currentTrack)
            self?.updateProgress(with: status.currentTime, until: status.duration)
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
            self?.updateVolume(with: volume)
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
            self?.updatePlayPause(with: displayIsPlaying)
        }
    }
    
    func handlePlay(dataArray: [Any], ack: SocketAckEmitter) {
        print("handle play a")

        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertOnPlay.self, from: jsonData) else { return }

        print("handle play b")

        let isPlaying = status.isPlaying,
        audioStatus = status.audioStatus
        let displayIsPlaying = isPlaying && (audioStatus == "State.Playing" || audioStatus == "State.Opening")
        print(displayIsPlaying)
        
        DispatchQueue.main.async { [weak self] in
            self?.updatePlayPause(with: displayIsPlaying)
        }
    }
    
    func updateArtwork(with artworkUrl: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let url = URL(string: "http://concert.acm.illinois.edu/" + artworkUrl)
            URLSession.shared.dataTask(with: url!) { data, response, error in
                guard let data = data else { return }

                let image = UIImage(data: data)
                let blurredImage = image?.blur(radius: 0.6)
                let colors = NSArray(ofColorsFrom: image, withFlatScheme: false) as! [UIColor]

                DispatchQueue.main.async { [weak self] in
                    self?.update(artworkImage: image, withBlurredArtworkImage: blurredImage)
                    self?.updateColors(with: colors)
                }
            }.resume()
        }
    }
    
    func updateProgress(with progress: Int, until duration: Int) {
//        progressBar.progress = Float(progress / duration)
    }
    
    func updateInfoLabel(with title: String) {
        infoLabel.text = title
    }
    
    func updatePlayPause(with isPlaying: Bool) {
        let image = isPlaying ? #imageLiteral(resourceName: "pause") : #imageLiteral(resourceName: "play")
        self.playPauseButton.setImage(image, for: .normal)
    }
    
    func updateVolume(with slider: Int) {
        self.volumeSlider.value = Float(slider)
    }

    func update(artworkImage: UIImage?, withBlurredArtworkImage blurredArtworkImage: UIImage?) {
        artworkImageView.image = artworkImage
        backgroundArtworkImageView.image = blurredArtworkImage
    }

    func updateColors(with colors: [UIColor]?) {
        infoLabel.textColor = colors?[0]
        progressBar.tintColor = colors?[4]
        volumeSlider.tintColor = colors?[4]
        
        playPauseButton.tintColor = colors?[2]
        skipButton.tintColor = colors?[2]
        viewQueueButton.tintColor = colors?[2]
    }
}
