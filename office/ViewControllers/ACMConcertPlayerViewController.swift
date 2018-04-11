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

final class ACMConcertPlayerViewController: UIViewController {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var infoLabel: MarqueeLabel!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var viewQueueButton: UIButton!

    let socketManger = SocketManager(socketURL: URL(string: "http://concert.acm.illinois.edu")!)
    let jsonDecoder = JSONDecoder()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSocket()

        artworkImageView.contentMode = .scaleAspectFill
        artworkImageView.clipsToBounds = true
        artworkImageView.layer.masksToBounds = true
        
        infoLabel.animationDelay = 2
        infoLabel.trailingBuffer = 24
        infoLabel.fadeLength = 16

        volumeSlider.minimumValue = 0
        volumeSlider.maximumValue = 100
        volumeSlider.minimumValueImage = #imageLiteral(resourceName: "volumeLow")
        volumeSlider.maximumValueImage = #imageLiteral(resourceName: "volumeHigh")
        volumeSlider.tintColor = UIColor.gray

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
        socketManger.defaultSocket.on("connected", callback: handleConnection)
        socketManger.defaultSocket.on("skipped", callback: handleConnection)
        socketManger.defaultSocket.on("volume_changed", callback: handleVolume)
        socketManger.defaultSocket.on("pause", callback: handlePause)
        socketManger.defaultSocket.on("play", callback: handlePlay)
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

    @IBAction func didChangeVolume() {
        let volume = Int(volumeSlider.value)
        socketManger.defaultSocket.emit("volume", volume)
    }

    // MARK: Handlers
    func handleConnection(dataArray: [Any], ack: SocketAckEmitter) {

        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertOnConnect.self, from: jsonData) else { return }

        DispatchQueue.main.async { [weak self] in
            self?.updateVolume(with: status.volume)
            self?.updateArtwork(with: status.thumbnail)
            self?.updatePlayPause(with: status.isPlaying)
            self?.updateInfoLabel(with: status.currentTrack)
            self?.updateProgress(with: status.currentTime, until: status.duration)
        }
    }
    
    func handleVolume(dataArray: [Any], ack: SocketAckEmitter) {
        
        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertVolume.self, from: jsonData) else { return }
        
        let volume = status.volume
        
        DispatchQueue.main.async { [weak self] in
            self?.updateVolume(with: volume)
        }
    }
    
    func handlePause(dataArray: [Any], ack: SocketAckEmitter) {
        
        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertOnPause.self, from: jsonData) else { return }
        
        let isPlaying = status.isPlaying,
        audioStatus = status.audioStatus
        let displayIsPlaying = isPlaying && (audioStatus == "State.Playing" || audioStatus == "State.Opening")
        print(displayIsPlaying)
        
        DispatchQueue.main.async { [weak self] in
            self?.updatePlayPause(with: displayIsPlaying)
        }
    }
    
    func handlePlay(dataArray: [Any], ack: SocketAckEmitter) {
        
        guard let jsonString = dataArray.first as? String,
            let jsonData = jsonString.data(using: .utf8),
            let status = try? jsonDecoder.decode(ACMConcertOnPlay.self, from: jsonData) else { return }
        
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
                if let data = data,
                let image = UIImage(data: data) {
                    let colors = NSArray(ofColorsFrom: image, withFlatScheme: false) as! [UIColor]
                    DispatchQueue.main.async { [weak self] in
                        self?.updateArtwork(with: image)
                        self?.updateColors(with: colors)
                    }
                }
            }.resume()
        }
    }
    
    func updateProgress(with progress: Int, until duration: Int) {
        progressSlider.setValue(Float(progress / duration), animated: false)
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

    func updateArtwork(with image: UIImage?) {
        artworkImageView.image = image
    }

    func updateColors(with colors: [UIColor]?) {
        view.backgroundColor = colors?[4] ?? UIColor.white
        infoLabel.textColor = colors?[1]
        progressSlider.tintColor = colors?[2]
        
        playPauseButton.tintColor = colors?[1]
        skipButton.tintColor = colors?[1]
        viewQueueButton.tintColor = colors?[1]
    }
}
