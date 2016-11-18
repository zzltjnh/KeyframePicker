//
//  PhotoLibraryVideosPickerViewController.swift
//  Example
//
//  Created by zhangzhilong on 2016/11/11.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import Photos
import KeyframePicker

class PhotoLibraryVideosPickerViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var videoModels: [VideoModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Select a Video"
        loadData()
    }
    
    func loadData() {
        // read videos from photo library
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil)
        
        fetchResult.enumerateObjects ({ (assetCollection, _, _) in
            let videoAssets = PHAsset.fetchAssets(in: assetCollection, options: nil)
            videoAssets.enumerateObjects ({ (asset, _, _) in
                var videoModel = VideoModel()
                videoModel.asset = asset
                self.videoModels.append(videoModel)
            })
        })
        
        collectionView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier ==  String(describing: KeyframeImageDisplayViewController.self) {
            let vc = segue.destination as! KeyframeImageDisplayViewController
            vc.image = sender as? KeyframeImage
        }
    }
}

extension PhotoLibraryVideosPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemWidth = (UIScreen.main.bounds.size.width - 5 * 5) / 4
        
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoLibraryPickerViewCell.self), for: indexPath) as! PhotoLibraryPickerViewCell
        
        // Configure the cell
        cell.videoModel = videoModels[indexPath.row]
        cell.updateUI()
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let videoModel = videoModels[indexPath.row]
        
        guard let asset = videoModel.asset else {
            return
        }
        
        // Get AVAsset from PHAsset
        PHImageManager.default().requestAVAsset(forVideo: asset, options: nil) { [weak self] (avAsset, _, _) in
            //perform on mainQueue
            DispatchQueue.main.async {
                let keyframePicker = KeyframePickerViewController.create()
                keyframePicker.asset = avAsset
                // set handler
                keyframePicker.generatedKeyframeImageHandler = { [weak self] image in
                    if let image = image {
                        //display generated image（present modal）
                        self?.performSegue(withIdentifier: String(describing: KeyframeImageDisplayViewController.self), sender: image)
                        print("generate image success")
                    } else {
                        print("generate image failed")
                    }
                }
                
                self?.navigationController?.pushViewController(keyframePicker, animated: true)
            }
        }
        
    }
}
