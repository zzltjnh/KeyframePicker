//
//  KeyframePickerVideoPlayerController.swift
//  KeyframePicker
//
//  Created by zhangzhilong on 2016/11/15.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import AVFoundation

let KeyframePickerVideoPlayerInterfaceAnimationDuration = 0.15

/// videoStatus
///
public enum KeyframePickerVideoPlayerPlaybackState {
    case unknown
    case prepared
    case playing
    case paused
    case stoped
    case failed
    case didPlayToEndTime
}

public enum KeyframePickerVideoPlayerStyle {
    /// navigationBar and bottomBar show
    case interfaceShow
    /// navigationBar and bottomBar hidden
    case interfaceHidden
    
    public mutating func toggle() {
        switch self {
        case .interfaceShow:
            self = .interfaceHidden
        case .interfaceHidden:
            self = .interfaceShow
        }
    }
}

public typealias KeyframePickerVideoPlayerProgressHandler = (CMTime) -> Void
public typealias KeyframePickerVideoPlayerPlayerPlaybackStateChangedHandler = (KeyframePickerVideoPlayerPlaybackState) -> Void

open class KeyframePickerVideoPlayerController: UIViewController {
    //MARK: - Public Properties
    public var asset: AVAsset?
    public var progressHandler: KeyframePickerVideoPlayerProgressHandler?
    public var playbackStateChangedHandler: KeyframePickerVideoPlayerPlayerPlaybackStateChangedHandler?
    public var style: KeyframePickerVideoPlayerStyle = .interfaceShow {
        didSet {
            _videoView.style = style
        }
    }
    
    //MARK: - Private Properties
    private lazy var _videoView: KeyframePickerVideoPlayerView = {
       let videoView = KeyframePickerVideoPlayerView(frame: CGRect.zero)
        videoView.videoFillMode = .resizeAspect
        videoView.player = self._player
        return videoView
    }()
    
    private lazy var _player: AVPlayer = {
        return AVPlayer(playerItem: self._playerItem)
    }()
    
    private lazy var _playerItem: AVPlayerItem? = {
        if let asset = self.asset {
            return AVPlayerItem(asset: asset)
        }
        return nil
    }()
    
    /// playback progress observer
    private var _timeObserver: Any?
    private var _timeScale: CMTimeScale {
        return asset?.duration.timescale ?? 600
    }
    
    /// playback state
    public private(set) var playbackState: KeyframePickerVideoPlayerPlaybackState = .unknown {
        didSet {
            playbackStateChangedHandler?(playbackState)
        }
    }
    
    //MARK: - Life Cycle
    deinit {
        // Remove Observers
        if let _timeObserver = _timeObserver {
            _player.removeTimeObserver(_timeObserver)
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override open func loadView() {
        self.view = _videoView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configTimeObserver()
        configNotifications()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if playbackState == .unknown { playbackState = .prepared }
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Player Actions
    
    /// play from beginning
    public func playFromBeginning() {
        seek(to: kCMTimeZero)
        playFromCurrentTime()
    }
    
    /// play from currentTime
    public func playFromCurrentTime() {
        guard playbackState != .unknown else {
            return
        }
        playbackState = .playing
        _player.play()
    }
    
    
    /// pause if playing
    public func pause() {
        guard playbackState == .playing else {
            return
        }
        _player.pause()
        playbackState = .paused
    }
    
    /// pause and seek to kCMTimeZero
    public func stop() {
        guard playbackState != .stoped else {
            return
        }
        _player.pause()
        seek(to: kCMTimeZero)
        playbackState = .stoped
    }
    
    /// seek to time
    ///
    /// - parameter time: 想要定格的时间
    public func seek(to time: CMTime) {
        _player.seek(to: time, toleranceBefore: CMTimeMake(0, _timeScale), toleranceAfter: CMTimeMake(0, _timeScale)) {_ in
            
        }
    }
    
    //MARK: - Private Methods
    
    /// observe playback progress
    private func configTimeObserver() {
        if let progressHandler = progressHandler {
            _timeObserver = _player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, _timeScale),
                                                            queue: DispatchQueue.main,
                                                            using: progressHandler)
        }
    }
    
    /// add playback notifications and application status notifications
    private func configNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(KeyframePickerVideoPlayerController.didPlayToEndTime), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyframePickerVideoPlayerController.failedToPlayToEndTime), name: Notification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyframePickerVideoPlayerController.applicationWillResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyframePickerVideoPlayerController.applicationDidEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    //MARK: - Notification Methods
    @objc private func didPlayToEndTime() {
        playbackState = .didPlayToEndTime
    }
    
    @objc private func failedToPlayToEndTime() {
        playbackState = .failed
    }
    
    @objc private func applicationWillResignActive() {
        pause()
    }
    
    @objc private func applicationDidEnterBackground() {
        pause()
    }
}

public enum KeyframePickerVideoFillMode: Int {
    case resizeAspect
    case resizeAspectFill
    case resize
    
    public var description: String {
        switch self {
        case .resizeAspect:
            return AVLayerVideoGravityResizeAspect
        case .resizeAspectFill:
            return AVLayerVideoGravityResizeAspectFill
        case .resize: return AVLayerVideoGravityResize
            
        }
    }
}

open class KeyframePickerVideoPlayerView: UIView {
    //MARK: - override
    override open class var layerClass: Swift.AnyClass {
        return AVPlayerLayer.self
    }
    
    //MARK: - Public Properties
    public var player: AVPlayer? {
        didSet {
            self.playerLayer.player = player
        }
    }
    
    public var playerLayer: AVPlayerLayer {
        return self.layer as! AVPlayerLayer
    }
    
    public var videoFillMode: KeyframePickerVideoFillMode = .resizeAspect {
        didSet {
            self.playerLayer.videoGravity = videoFillMode.description
        }
    }
    
    public var playerLayerBackgroundColor = UIColor.white.cgColor {
        didSet {
            self.playerLayer.backgroundColor = playerLayerBackgroundColor
        }
    }
    
    public var style: KeyframePickerVideoPlayerStyle = .interfaceShow {
        didSet {
            var color = UIColor.white.cgColor
            switch style {
            case .interfaceShow:
                color = UIColor.white.cgColor
            case .interfaceHidden:
                color = UIColor.black.cgColor
            }
            
            UIView.animate(withDuration: KeyframePickerVideoPlayerInterfaceAnimationDuration) {
                self.playerLayerBackgroundColor = color
            }
        }
    }
    
    //MARK: - Init Related
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.playerLayer.backgroundColor = playerLayerBackgroundColor
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
