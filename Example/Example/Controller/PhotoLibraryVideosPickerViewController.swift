//
//  PhotoLibraryVideosPickerViewController.swift
//  Example
//
//  Created by zhangzhilong on 2016/11/11.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import Photos

class PhotoLibraryVideosPickerViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var videoModels: [VideoModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Photo Library"
        loadData()
    }
    
    func loadData() {
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: nil)
        
        fetchResult.enumerateObjects ({ (assetCollection, idx, stop) in
            let videoAssets = PHAsset.fetchAssets(in: assetCollection, options: nil)
            videoAssets.enumerateObjects ({ (asset, idx1, stop1) in
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
}

extension PhotoLibraryVideosPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return videoModels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PhotoLibraryPickerViewCell.self), for: indexPath) as! PhotoLibraryPickerViewCell
        
        // Configure the cell
        cell.videoModel = videoModels[indexPath.row]
        cell.updateUI()
        
        return cell
    }
}
