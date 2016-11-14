//
//  KeyframePickerCollectionViewCell.swift
//  KeyframePicker
//
//  Created by zhangzhilong on 2016/11/14.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit

open class KeyframePickerCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    public var keyframeImage: KeyframeImage?
    
    open func updateUI() {
        imageView.image = keyframeImage?.image
    }
}
