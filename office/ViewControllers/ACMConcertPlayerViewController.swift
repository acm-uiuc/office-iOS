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
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var viewQueueButton: UIButton!

    lazy var acmConcertSocket = ACMConcertSocket(delegate: self)
    
    var timer: Timer?
    var duration = 1
    var progress = 1

    override func viewDidLoad() {
        super.viewDidLoad()

        waveView.realWaveColor = UIColor.white.withAlphaComponent(1)
        waveView.maskWaveColor = UIColor.white.withAlphaComponent(0.3)
        waveView.waveSpeed = 0.75
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
        acmConcertSocket.setupSocket()
        NotificationCenter.default.addObserver(
            acmConcertSocket,
            selector: #selector(ACMConcertSocket.setupSocket),
            name: .UIApplicationDidBecomeActive, object: nil
        )
        NotificationCenter.default.addObserver(
            acmConcertSocket,
            selector: #selector(ACMConcertSocket.teardownSocket),
            name: .UIApplicationWillResignActive, object: nil
        )
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(acmConcertSocket, name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(acmConcertSocket, name: .UIApplicationWillResignActive, object: nil)
        acmConcertSocket.teardownSocket()
    }

    // MARK: Actions
//    @IBAction func button() {
//        socketManager.defaultSocket.emit("pause")
//    }
//
//    @IBAction func didChangeVolume() {
//        let volume = Int(volumeSlider.value)
//        socketManager.defaultSocket.emit("volume", volume)
//    }
    
    func updateArtwork(with url: URL?) {
        DispatchQueue.global(qos: .userInitiated).async {
            URLSession.shared.dataTask(with: url!) { data, response, error in
                guard let data = data else { return }

                let image = UIImage(data: data)
                let blurredImage = image?.blur(radius: 0.6)
                let colors = NSArray(ofColorsFrom: image, withFlatScheme: false) as! [UIColor]

                DispatchQueue.main.async { [weak self] in
                    self?.artworkImageView.image = image
                    self?.backgroundArtworkImageView.image = blurredImage
                    self?.updateColors(with: colors)
                }
            }.resume()
        }
    }
    
    @objc func updateProgress() {
        if progress >= duration {
            timer?.invalidate()
        }
        print(progress, duration)
        let (remaining_hr, remaining_min, remaining_sec) = secondsToHoursMinutesSeconds(seconds: (duration - progress)/1000)
        let fraction = Float(progress) / Float(duration)
        print(fraction)
        DispatchQueue.main.async { [weak self] in
            self?.progressBar.setProgress(fraction, animated: false)
        }
        let (elapsed_hr, elapsed_min, elapsed_sec) = secondsToHoursMinutesSeconds(seconds: progress/1000)
        elapsedTimeLabel.text = (elapsed_hr != "00" ? "\(elapsed_hr):" : "") + "\(elapsed_min):\(elapsed_sec)"
        totalTimeLabel.text = "-" + (remaining_hr != "00" ? "\(remaining_hr):" : "") + "\(remaining_min):\(remaining_sec)"
        progress += 1000
    }

    func updateColors(with colors: [UIColor]?) {
        infoLabel.textColor = colors?[0]
        progressBar.progressTintColor = colors?[2]
        progressBar.trackTintColor = UIColor.lightGray
        volumeSlider.tintColor = colors?[2]
        
        playPauseButton.tintColor = colors?[2]
        skipButton.tintColor = colors?[2]
        viewQueueButton.tintColor = colors?[2]
    }
    
    func secondsToHoursMinutesSeconds(seconds : Int) -> (String, String, String) {
        if seconds <= 0 {
            return ("00", "00", "00")
        }
        return (zfill(String(seconds / 3600), 2),
                zfill(String((seconds % 3600) / 60), 2),
                zfill(String((seconds % 3600) % 60), 2))
    }
    
    public func zfill(_ input: String, _ length: Int) -> String {
        // use String.init(format: String, vargs...)
        return String.init(format: "%0d.0s", arguments: [length, input])
    }
}

extension ACMConcertPlayerViewController: ACMConcertSocketDelegate {
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceivePlayStateUpdate isPlaying: Bool) {
        let image = isPlaying ? #imageLiteral(resourceName: "pause") : #imageLiteral(resourceName: "play")
        self.playPauseButton.setImage(image, for: .normal)
    }
    
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveVolumeUpdate newVolume: Int) {
        self.volumeSlider.value = Float(newVolume)
    }
    
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveProgressUpdate progress: Int, didReceiveDurationUpdate duration: Int) {
        if timer?.isValid == false {
            timer = Timer.scheduledTimer(
                timeInterval: 1,
                target: self,
                selector: #selector(updateProgress),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveInfoLabel trackName: String?) {
        infoLabel.text = trackName
    }
    
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveNewArtwork url: URL?) {
        updateArtwork(with: url)
    }
}

