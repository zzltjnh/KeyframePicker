//
//  KeyframePickerViewController.swift
//  KeyframePicker
//
//  Created by zhangzhilong on 2016/11/11.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

open class KeyframePickerViewController: UIViewController {

    //MARK: - Public Properties
    public var asset: AVAsset?
    ///videoPath（local or remote）
    public var videoPath: String?
    ///generat image completed closure
    public var generatedKeyframeImageHandler: SingleImageClosure?
    public let imageGenerator = KeyframeImageGenerator()
    public var playbackState: KeyframePickerVideoPlayerPlaybackState {
        return videoPlayerController.playbackState
    }
    ///current playback time of video
    public private(set) var currentTime = kCMTimeZero
    
    //MARK: - ChildViewControllers
    /// cursor Controller
    weak var cursorContainerViewController: KeyframePickerCursorViewController!
    /// video player Controller
    weak var videoPlayerController: KeyframePickerVideoPlayerController!
    
    //MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cursorContainerView: UIView!
    @IBOutlet weak var bottomContainerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var bigPlayButton: UIButton!
    @IBOutlet weak var cursorContainerViewCenterConstraint: NSLayoutConstraint!
    
    //MARK: - Private Properties
    fileprivate var _asset: AVAsset? {
        if let asset = asset {
            return asset
        }
        
        if let videoPath = videoPath , videoPath.characters.count > 0 {
            var videoURL = URL(string: videoPath)
            if videoURL == nil || videoURL?.scheme == nil {
                videoURL = URL(fileURLWithPath: videoPath)
            }
            
            if let videoURL = videoURL {
                let urlAsset = AVURLAsset(url: videoURL, options: nil)
                return urlAsset
            }
        }
        
        return nil
    }
    /// progress bar images
    fileprivate var _displayKeyframeImages: [KeyframeImage] = []
    private var _statusBarHidden = false
    
    //MARK: - Override
    override open var prefersStatusBarHidden: Bool {
        return _statusBarHidden
    }
    
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    //MARK: - Class Method
    open class func create() -> KeyframePickerViewController {
        let storyBoard = UIStoryboard(name: "KeyframePicker", bundle: Bundle(for: KeyframePickerViewController.self))
        return storyBoard.instantiateViewController(withIdentifier: String(describing: KeyframePickerViewController.self)) as! KeyframePickerViewController
    }

    //MARK: - Life Cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        loadData()
        configUI()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Load Data
    open func loadData() {
        if let _asset = _asset {
            imageGenerator.generateDefaultSequenceOfImages(from: _asset) { [weak self] in
                self?._displayKeyframeImages.append(contentsOf: $0)
                self?.updateUI()
            }
        }
    }
    
    //MARK: - UI Related
    open func configUI() {
        //always Bounce
        collectionView.alwaysBounceHorizontal = true
        //左右留白（屏幕一半宽），目的是让collectionView中的第一个和最后一个cell能滚动到屏幕中央
        collectionView.contentInset = UIEdgeInsets(top: 0, left: UIScreen.main.bounds.size.width / 2, bottom: 0, right: UIScreen.main.bounds.size.width / 2)
        
        cursorContainerViewController.seconds = 0
    }
    
    open func updateUI() {
        collectionView.reloadData()
    }
    
    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == String(describing: KeyframePickerCursorViewController.self) {
            self.cursorContainerViewController = segue.destination as! KeyframePickerCursorViewController
        } else if segue.identifier == String(describing: KeyframePickerVideoPlayerController.self) {
            self.videoPlayerController = segue.destination as! KeyframePickerVideoPlayerController
            self.videoPlayerController.asset = _asset
            self.videoPlayerController.playbackStateChangedHandler = {
                [weak self] playbackState in
                self?.videoPlayerPlaybackStateChanged(to: playbackState)
            }
            self.videoPlayerController.progressHandler = {
                [weak self] time in
                self?.videoPlayerPlayback(to: time)
            }
        }
    }
    
    //MARK: - Button Actions
    @IBAction func onPlay(_ sender: AnyObject) {
        if playbackState == .didPlayToEndTime {
            videoPlayerController.playFromBeginning()
        } else {
            videoPlayerController.playFromCurrentTime()
        }
    }
    
    @IBAction func onPause(_ sender: AnyObject) {
        videoPlayerController.pause()
    }
    
    @IBAction func onBigPlay(_ sender: AnyObject) {
        onPlay(sender)
    }
    
    @IBAction func onDone(_ sender: AnyObject) {
        guard let _asset = _asset else {
            return
        }
        
        guard playbackState != .unknown else {
            return
        }
        
        // pause if playing before generate image
        videoPlayerController.pause()
        
        imageGenerator.generateSingleImage(from: _asset, time: currentTime) {
            [weak self] image in
            self?.generatedKeyframeImageHandler?(image)
        }
    }
    
    @IBAction func onTapActionContentView(_ sender: AnyObject) {
        //播放器样式反转
        videoPlayerController.style.toggle()
        if videoPlayerController.style == .interfaceHidden,
            videoPlayerController.playbackState != .playing {
            bigPlayButton.isHidden = false
        } else if videoPlayerController.playbackState == .prepared {
            bigPlayButton.isHidden = false
        } else {
            bigPlayButton.isHidden = true
        }
        
        //toggle bottomBar、navigationBar
        navigationController?.setNavigationBarHidden(!(navigationController?.isNavigationBarHidden)!, animated: false)
        
        var alpha = 0
        if bottomContainerView.isHidden {
            bottomContainerView.isHidden = false
            alpha = 1
        }
        UIView.animate(withDuration: KeyframePickerVideoPlayerInterfaceAnimationDuration, animations: {
            self.bottomContainerView.alpha = CGFloat(alpha)
            }) { _ in
                if alpha == 0 {
                    self.bottomContainerView.isHidden = true
                }
        }
        //toggle statusBar
        _statusBarHidden = !_statusBarHidden
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    //MARK: - PlaybackState Changed
    func videoPlayerPlaybackStateChanged(to playbackState: KeyframePickerVideoPlayerPlaybackState) {
        if playbackState != .prepared {
            bigPlayButton.isHidden = true
        }
        
        if playbackState == .playing {
            playButton.isHidden = true
            pauseButton.isHidden = false
        } else if playbackState == .paused {
            playButton.isHidden = false
            pauseButton.isHidden = true
        } else if playbackState == .stoped {
            playButton.isHidden = false
            pauseButton.isHidden = true
        } else if playbackState == .failed {
            playButton.isHidden = false
            pauseButton.isHidden = true
            bigPlayButton.isHidden = false
        } else if playbackState == .didPlayToEndTime {
            playButton.isHidden = false
            pauseButton.isHidden = true
            if videoPlayerController.style == .interfaceHidden {
                bigPlayButton.isHidden = false
            }
        }
    }
    
    //MARK: - Playback Progress Changed
    func videoPlayerPlayback(to time: CMTime) {
        //save current play time
        currentTime = time
        
        guard let _asset = _asset, videoPlayerController.playbackState == .playing else {
            return
        }
        let percent = time.seconds / _asset.duration.seconds
        let videoTrackLength = KeyframePickerViewCellWidth * _displayKeyframeImages.count
        let position = CGFloat(videoTrackLength) * CGFloat(percent) - UIScreen.main.bounds.size.width / 2
        collectionView.contentOffset = CGPoint(x: position, y: collectionView.contentOffset.y)
        cursorContainerViewController.seconds = time.seconds
    }
}

private let KeyframePickerViewCellWidth = 67
//MARK: - UICollectionView Methods
extension KeyframePickerViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _displayKeyframeImages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: KeyframePickerCollectionViewCell.self), for: indexPath) as! KeyframePickerCollectionViewCell
        cell.keyframeImage = _displayKeyframeImages[indexPath.row]
        cell.updateUI()
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat(KeyframePickerViewCellWidth), height: collectionView.frame.size.height)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if playbackState == .playing {
            videoPlayerController.pause()
        } else {
            videoPlayerController.playFromCurrentTime()
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //_asset is nil or videoPlayer not readyForDisplay
        guard  let _asset = _asset, videoPlayerController.playbackState != .unknown else {
            return
        }
        //playing
        guard videoPlayerController.playbackState != .playing else {
            return
        }
        //length of video track
        let videoTrackLength = KeyframePickerViewCellWidth * _displayKeyframeImages.count
        //current position
        var position = scrollView.contentOffset.x + UIScreen.main.bounds.size.width / 2
        if position < 0 {
            cursorContainerViewCenterConstraint.constant = -position
        } else if position > CGFloat(videoTrackLength) {
            cursorContainerViewCenterConstraint.constant = CGFloat(videoTrackLength) - position
        }
        position = max(position, 0)
        position = min(position, CGFloat(videoTrackLength))
        //percent of current position in progress bar
        let percent = position / CGFloat(videoTrackLength)
        //
        var currentSecond = _asset.duration.seconds * Double(percent)
        currentSecond = max(currentSecond, 0)
        currentSecond = min(currentSecond, _asset.duration.seconds)
        //
        let currentTime = CMTimeMakeWithSeconds(currentSecond, _asset.duration.timescale)
        //update cursor time value
        cursorContainerViewController.seconds = currentSecond
        //seek to currentTime
        videoPlayerController.seek(to: currentTime)
    }
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        videoPlayerController.pause()
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
}
