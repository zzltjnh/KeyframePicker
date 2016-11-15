//
//  KeyframePickerVideoPlayerController.swift
//  KeyframePicker
//
//  Created by zhangzhilong on 2016/11/15.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import AVFoundation

class KeyframePickerVideoPlayerController: UIViewController {
    public var asset: AVAsset?
    
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
    
    //MARK: - Life Cycle
    override func loadView() {
        self.view = _videoView
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
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
        _player.seek(to: time, toleranceBefore: CMTimeMake(0, 600), toleranceAfter: CMTimeMake(0, 600)) {_ in 
            
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

class KeyframePickerVideoPlayerView: UIView {
    //MARK: - override
    override class var layerClass: Swift.AnyClass {
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
