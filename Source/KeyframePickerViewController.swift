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
    ///视频路径（本地或远程）
    public var videoPath: String?
    ///生成图片完成会执行该闭包
    public var generatedKeyframeImageHandler: SingleImageClosure?
    public let imageGenerator = KeyframeImageGenerator()
    public var playbackState: KeyframePickerVideoPlayerPlaybackState {
        return videoPlayerController.playbackState
    }
    ///视频当前播放时间
    public private(set) var currentTime = kCMTimeZero
    
    //MARK: - ChildViewControllers
    /// 游标Controller
    weak var cursorContainerViewController: KeyframePickerCursorViewController!
    /// 播放器Controller
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
    /// 底部进度条所有图片的数组
    fileprivate var _displayKeyframeImages: [KeyframeImage] = []
    private var _statusBarHidden = false
    
    //MARK: - Override
    override open var prefersStatusBarHidden: Bool {
        return _statusBarHidden
    }
    
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
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
        //即使内容很少也允许collectionView有弹性效果
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
        
        //toggle底部工具条、导航条
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
        //toggle状态栏
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
        //记录当前视频时间
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
        //资源为空或播放器未准备好
        guard  let _asset = _asset, videoPlayerController.playbackState != .unknown else {
            return
        }
        //播放中
        guard videoPlayerController.playbackState != .playing else {
            return
        }
        //视频轨道即进度条长度
        let videoTrackLength = KeyframePickerViewCellWidth * _displayKeyframeImages.count
        //当前位置
        var position = scrollView.contentOffset.x + UIScreen.main.bounds.size.width / 2
        if position < 0 {
            cursorContainerViewCenterConstraint.constant = -position
        } else if position > CGFloat(videoTrackLength) {
            cursorContainerViewCenterConstraint.constant = CGFloat(videoTrackLength) - position
        }
        position = max(position, 0)
        position = min(position, CGFloat(videoTrackLength))
        //当前拖动位置占视频的百分比
        let percent = position / CGFloat(videoTrackLength)
        //当前拖动到视频的秒数
        let currentSecond = _asset.duration.seconds * Double(percent)
        //当前拖动到视频的time
        let currentTime = CMTimeMakeWithSeconds(currentSecond, _asset.duration.timescale)
        //设置游标时间值
        cursorContainerViewController.seconds = currentSecond
        //将播放器切换到当前帧
        videoPlayerController.seek(to: currentTime)
    }
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        videoPlayerController.pause()
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
    }
}
