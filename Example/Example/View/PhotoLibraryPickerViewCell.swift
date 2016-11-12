//
//  PhotoLibraryPickerViewCell.swift
//  Example
//
//  Created by zhangzhilong on 2016/11/11.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import Photos

class PhotoLibraryPickerViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var videoModel: VideoModel?
    
    func updateUI() {
        guard let asset = videoModel?.asset else {
            return
        }
        //获取视频缩略图
        let screenSize = UIScreen.main.bounds.size
        let thumbnailsSize = CGSize(width:screenSize.width / 4 * UIScreen.main.scale, height:screenSize.width / 4 * UIScreen.main.scale)
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        PHImageManager.default().requestImage(for: asset, targetSize: thumbnailsSize, contentMode: .aspectFill, options: options, resultHandler: { [weak self] (image, info) in
            self?.imageView.image = image
        })

    }
}
