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
import UIImageColors
import YXWaveView

final class ACMConcertPlayerViewController: UIViewController {
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var artworkImageContainerView: UIView!
    @IBOutlet weak var backgroundArtworkImageView: UIImageView!


    @IBOutlet weak var waveView: YXWaveView!
    @IBOutlet weak var textContainerView: UIView!


    @IBOutlet weak var infoLabel: MarqueeLabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var viewQueueButton: UIButton!


    lazy var acmConcertSocket = ACMConcertSocket(delegate: self)
    var timer: Timer?
    var duration = 1
    var progress = 1
    var pauseImage = #imageLiteral(resourceName: "pause")
    var playImage = #imageLiteral(resourceName: "play")

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
    @IBAction func didTogglePlayPause() {
        acmConcertSocket.send(event: .pause)
    }

    @IBAction func didChangeVolume() {
        let value = Int(volumeSlider.value)
        acmConcertSocket.send(event: .volume(value))
    }

    @IBAction func didSkipSong() {
        acmConcertSocket.send(event: .skip)
    }

    func updateArtwork(with url: URL?) {
        guard let unwrappedUrl = url else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            URLSession.shared.dataTask(with: unwrappedUrl) { data, response, error in
                guard let data = data else { return }

                let image = UIImage(data: data)
                let blurredImage = image?.blur(radius: 0.6)
                let colors = image?.getColors()

                DispatchQueue.main.async { [weak self] in
                    self?.artworkImageView.image = image
                    self?.backgroundArtworkImageView.image = blurredImage
                    self?.update(colors: colors)
                }
            }.resume()
        }
    }

    @objc func updateProgress() {
        if progress >= duration {
            timer?.invalidate()
        }
        let fraction = Float(progress) / Float(duration)
        #if DEBUG
            print("progress fraction: \(fraction)")
        #endif
        DispatchQueue.main.async { [weak self] in
            self?.progressBar.setProgress(fraction, animated: false)
        }

        let elapsed = secondsToHoursMinutesSeconds(seconds: progress, elapsed: true)
        let remain = secondsToHoursMinutesSeconds(seconds: (duration - progress), elapsed: false)
        elapsedTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12.0, weight: UIFont.Weight.regular)
        remainingTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12.0, weight: UIFont.Weight.regular)
        elapsedTimeLabel.text = elapsed
        remainingTimeLabel.text = remain
        progress += 1
    }

    func update(colors: UIImageColors?) {
        infoLabel.textColor = colors?.primary
        progressBar.progressTintColor = colors?.secondary
        progressBar.trackTintColor = colors?.detail
        volumeSlider.maximumTrackTintColor = colors?.detail
        volumeSlider.minimumTrackTintColor = colors?.secondary

        playPauseButton.tintColor = colors?.secondary
        skipButton.tintColor = colors?.secondary
        viewQueueButton.tintColor = colors?.secondary

        elapsedTimeLabel.textColor = colors?.secondary
        remainingTimeLabel.textColor = colors?.secondary

        let waveAlpha: CGFloat = 0.3
        let textViewAlpha = 1 - pow((1 - waveAlpha), 2)

        textContainerView.backgroundColor = colors?.background.withAlphaComponent(textViewAlpha) ?? UIColor.white.withAlphaComponent(textViewAlpha)
        waveView.realWaveColor = colors?.background.withAlphaComponent(waveAlpha) ?? UIColor.white.withAlphaComponent(waveAlpha)
        waveView.maskWaveColor = colors?.background?.withAlphaComponent(waveAlpha) ?? UIColor.white.withAlphaComponent(waveAlpha)
    }

    func secondsToHoursMinutesSeconds(seconds: Int, elapsed: Bool) -> String {
        let hr = seconds / 3600
        let min = (seconds % 3600) / 60
        let sec = (seconds % 3600) % 60
        #if DEBUG
            print("hr: \(hr) min: \(min) sec: \(sec)")
        #endif
        if elapsed {
            if hr > 0 {
                return String(format: "%d:%02d:%02d", hr, min, sec)
            } else {
                return String(format: "%d:%02d", min, sec)
            }
        } else {
            if hr > 0 {
                return String(format: "-%d:%02d:%02d", hr, min, sec)
            } else {
                return String(format: "-%d:%02d", min, sec)
            }
        }
    }
}

extension ACMConcertPlayerViewController: ACMConcertSocketDelegate {
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceivePlayStateUpdate isPlaying: Bool) {
        let image = isPlaying ? pauseImage : playImage
        self.playPauseButton.setImage(image, for: .normal)
        if !isPlaying {
            timer?.invalidate()
        } else {
            if timer?.isValid != true {
                timer = Timer.scheduledTimer(
                    timeInterval: 1,
                    target: self,
                    selector: #selector(updateProgress),
                    userInfo: nil,
                    repeats: true
                )
            }
        }
        
    }

    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveVolumeUpdate newVolume: Int) {
        self.volumeSlider.value = Float(newVolume)
    }
    
    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveProgressUpdate progress: Int, didReceiveDurationUpdate duration: Int) {
        self.duration = duration
        self.progress = progress
    }

    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveInfoLabel trackName: String?) {
        infoLabel.text = trackName
    }

    func acmConcertSocket(_ acmConcertSocket: ACMConcertSocket, didReceiveNewArtwork url: URL?) {
        updateArtwork(with: url)
    }
}
