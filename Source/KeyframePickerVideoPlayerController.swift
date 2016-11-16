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
/// 播放器状态
///
/// - unknown:          未知（默认值）
/// - prepared:         已准备好
/// - playing:          播放中
/// - paused:           已暂停
/// - stoped:           停止
/// - failed:           失败
/// - didPlayToEndTime: 播放到结尾
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
    /// 导航条显示
    case interfaceShow
    /// 导航条隐藏
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
    
    /// 播放进度观察者
    private var _timeObserver: Any?
    private var _timeScale: CMTimeScale {
        return asset?.duration.timescale ?? 600
    }
    
    /// 播放状态
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
        
        playbackState = .prepared
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Player Actions
    
    /// 从头开始播放
    public func playFromBeginning() {
        seek(to: kCMTimeZero)
        playFromCurrentTime()
    }
    
    /// 从当前进度开始播放
    public func playFromCurrentTime() {
        guard playbackState != .unknown else {
            return
        }
        playbackState = .playing
        _player.play()
    }
    
    
    /// 如果播放器正在播放，将其暂停
    public func pause() {
        guard playbackState == .playing else {
            return
        }
        _player.pause()
        playbackState = .paused
    }
    
    /// 停止播放并将视频画面切回第一帧
    public func stop() {
        guard playbackState != .stoped else {
            return
        }
        _player.pause()
        seek(to: kCMTimeZero)
        playbackState = .stoped
    }
    
    /// 将视频画面定格到某一帧
    ///
    /// - parameter time: 想要定格的时间
    public func seek(to time: CMTime) {
        _player.seek(to: time, toleranceBefore: CMTimeMake(0, _timeScale), toleranceAfter: CMTimeMake(0, _timeScale)) {_ in
            
        }
    }
    
    //MARK: - Private Methods
    
    /// 观察播放进度
    private func configTimeObserver() {
        if let progressHandler = progressHandler {
            _timeObserver = _player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, _timeScale),
                                                            queue: DispatchQueue.main,
                                                            using: progressHandler)
        }
    }
    
    /// 添加播放相关通知
    private func configNotifications() {
        //添加播放完成和播放失败通知
        NotificationCenter.default.addObserver(self, selector: #selector(didPlayToEndTime), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlayToEndTime), name: Notification.Name.AVPlayerItemFailedToPlayToEndTime, object: nil)
    }
    
    //MARK: - Notification Methods
    @objc private func didPlayToEndTime() {
        playbackState = .didPlayToEndTime
    }
    
    @objc private func failedToPlayToEndTime() {
        playbackState = .failed
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
