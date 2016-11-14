//
//  KeyframePickerViewController.swift
//  KeyframePicker
//
//  Created by zhangzhilong on 2016/11/11.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import AVFoundation

open class KeyframePickerViewController: UIViewController {

    //MARK: - Public Properties
    public var asset: AVAsset?
    public var videoPath: String?
    public let imageGenerator = KeyframeImageGenerator()
    
    //MARK: - Private Properties
    @IBOutlet weak var collectionView: UICollectionView!
    private var _asset: AVAsset? {
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
    
    fileprivate var displayKeyframeImages: [KeyframeImage] = []

    //MARK: - Life Cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        loadData()
        configUI()
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Load Data
    open func loadData() {
        if let _asset = _asset {
            imageGenerator.generateDefaultSequenceOfImages(from: _asset) { [weak self] in
                self?.displayKeyframeImages.append(contentsOf: $0)
                self?.updateUI()
            }
        }
    }
    
    //MARK: - UI Related
    open func configUI() {
        collectionView.alwaysBounceHorizontal = true
        collectionView.contentInset = UIEdgeInsets(top: 0, left: UIScreen.main.bounds.size.width / 2, bottom: 0, right: UIScreen.main.bounds.size.width / 2)
    }
    
    open func updateUI() {
        collectionView.reloadData()
    }
    
}

//MARK: - UICollectionView Methods
extension KeyframePickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayKeyframeImages.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: KeyframePickerCollectionViewCell.self), for: indexPath) as! KeyframePickerCollectionViewCell
        cell.keyframeImage = displayKeyframeImages[indexPath.row]
        cell.updateUI()
        
        return cell
    }
}
