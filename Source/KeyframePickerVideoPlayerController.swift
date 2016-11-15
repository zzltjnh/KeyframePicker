//
//  KeyframePickerVideoPlayerController.swift
//  KeyframePicker
//
//  Created by zhangzhilong on 2016/11/15.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import AVFoundation

public typealias KeyframePickerVideoPlayerProgressHandler = (CMTime) -> Void

open class KeyframePickerVideoPlayerController: UIViewController {
    //MARK: - Public Properties
    public var asset: AVAsset?
    public var progressHandler: KeyframePickerVideoPlayerProgressHandler?
    
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
    
    private var _timeObserver: Any?
    private var _timeScale: CMTimeScale {
        return asset?.duration.timescale ?? 600
    }
    
    //MARK: - Life Cycle
    deinit {
        if let _timeObserver = _timeObserver {
            _player.removeTimeObserver(_timeObserver)
        }
    }
    
    override open func loadView() {
        self.view = _videoView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configTimeObserver()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Player Actions
    public func play() {
        _player.play()
    }
    
    public func pause() {
        _player.pause()
    }
    
    public func seek(to time: CMTime) {
        _player.seek(to: time, toleranceBefore: CMTimeMake(0, _timeScale), toleranceAfter: CMTimeMake(0, _timeScale)) {_ in
            
        }
    }
    
    //MARK: - Private Methods
    private func configTimeObserver() {
        if let progressHandler = progressHandler {
            _timeObserver = _player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, _timeScale),
                                                            queue: DispatchQueue.main,
                                                            using: progressHandler)
        }
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
            self.playerLayer.backgroundColor = UIColor.white.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.playerLayer.backgroundColor = playerLayerBackgroundColor
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
