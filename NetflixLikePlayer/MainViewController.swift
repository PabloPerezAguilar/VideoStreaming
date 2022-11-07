//
//  MainViewController.swift
//  NetflixLikePlayer
//
//  Created by Consultant on 8/2/22.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController {

    let videoPlayerView = UIView()
    var player: AVPlayer?
    var timeObserver: Any?
    var timer: Timer?
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressSlider: UISlider!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var fowardButton: UIButton!
    @IBOutlet weak var backwardButton: UIButton!
    
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupVideoLayer()
        resetTimer()
        setupTouchScreen()
    }
    
    func setupView(){
        setupPlayerView()
        setupButton()
    }
    
    func setupPlayerView() {
        videoPlayerView.translatesAutoresizingMaskIntoConstraints = false
        let viewConstraints = setUpViewConstraints()
        view.addSubview(videoPlayerView)
        view.addConstraints(viewConstraints)
        view.sendSubviewToBack(videoPlayerView)
    }

    func setUpViewConstraints() -> [NSLayoutConstraint]{
        let topConstraint = NSLayoutConstraint(item: videoPlayerView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: videoPlayerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: videoPlayerView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: videoPlayerView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        
        return [topConstraint, bottomConstraint, leadingConstraint, trailingConstraint]
    }
    
    func setupButton(){
        playButton.imageView?.contentMode = .scaleAspectFit
    }
    
    func setupTouchScreen(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        view.addGestureRecognizer(tapGesture)
    }

    func setupVideoLayer(){
        guard let url = URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4") else { return }
        player = AVPlayer(url: url)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoPlayerView.bounds
        videoPlayerView.layer.addSublayer(playerLayer)
        
        let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main, using:{ elapsedTime in self.updateVideoPlayerState() })
        
    }
    
    func updateVideoPlayerState(){
        guard let currentTime = player?.currentTime() else { return }
        if let currentItem = player?.currentItem {
            let duration = currentItem.duration
            if(CMTIME_IS_INVALID(duration)){ return }
            let currentTime = currentItem.currentTime()
            updateVideoPlayerSlider(currentTime: currentTime, duration: duration)
            updateTimeRemainingLabel(currentTime: currentTime, duration: duration)
        }else{
            updateVideoPlayerSlider(currentTime: currentTime)
        }
    }
    
    func updateVideoPlayerSlider(currentTime: CMTime, duration: CMTime? = nil){
        let value = duration != nil ? Float(CMTimeGetSeconds(currentTime) /  CMTimeGetSeconds(duration!)) : Float(CMTimeGetSeconds(currentTime))
        progressSlider.value = value
    }
    
    func updateTimeRemainingLabel(currentTime: CMTime, duration: CMTime){
        let currentTimeInSeconds = CMTimeGetSeconds(currentTime)
        let totalTimeInSeconds = CMTimeGetSeconds(duration)
        let remainingTimeInSeconds = totalTimeInSeconds - currentTimeInSeconds
        
        let mins = remainingTimeInSeconds / 60
        let secs = remainingTimeInSeconds.truncatingRemainder(dividingBy: 60)
        let timeFormatter = NumberFormatter()
        timeFormatter.minimumIntegerDigits = 2
        timeFormatter.maximumFractionDigits = 0
        timeFormatter.roundingMode = .down
        guard let minsStr = timeFormatter.string(from: NSNumber(value: mins)), let secsStr = timeFormatter.string(from: NSNumber(value: secs)) else { return }
        
        timeRemainingLabel.text = "\(minsStr):\(secsStr)"
    }
    
    func resetTimer(){
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
    }
    
    @objc func hideControls(){
        playButton.isHidden = !playButton.isHidden
        progressSlider.isHidden = !progressSlider.isHidden
        timeRemainingLabel.isHidden = !timeRemainingLabel.isHidden
        titleLabel.isHidden = !titleLabel.isHidden
        fowardButton.isHidden = !fowardButton.isHidden
        backwardButton.isHidden = !backwardButton.isHidden
    }
    
    @objc func toggleControls(){
        hideControls()
        resetTimer()
    }

    @IBAction func playPauseTapped(_ sender: Any) {
        guard let player = player else { return }
        if !player.isPlaying{
            player.play()
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }else{
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            player.pause()
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        guard let duration = player?.currentItem?.duration else { return }
        let value = Float64(progressSlider.value) * CMTimeGetSeconds(duration)
        let seekTime = CMTime(value: CMTimeValue(value), timescale: 1)
        player?.seek(to: seekTime)
    }
    
    @IBAction func jumpFowardTapped(_ sender: Any) {
        guard let currentTime = player?.currentTime() else { return }
        let newFowardTimeInSeconds = CMTimeGetSeconds(currentTime).advanced(by: 10)
        let seekTime = CMTime(value: CMTimeValue(newFowardTimeInSeconds), timescale: 1)
        player?.seek(to: seekTime)
    }
    
    @IBAction func jumpBackardsTapped(_ sender: Any) {
        guard let currentTime = player?.currentTime() else { return }
        let newbackwardTimeInSeconds = CMTimeGetSeconds(currentTime).advanced(by: -10)
        let seekTime = CMTime(value: CMTimeValue(newbackwardTimeInSeconds), timescale: 1)
        player?.seek(to: seekTime)
    }
    
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
