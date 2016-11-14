//
//  KeyframeImageGenerator.swift
//  KeyframePicker
//
//  Created by zhangzhilong on 2016/11/11.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import Foundation
import AVFoundation


/// 封装关键帧图片数据模型
open class KeyframeImage: NSObject {
    
    /// 关键帧图片
    public var image: UIImage
    
    /// 将要生成图片的时间
    public var requestedTime: CMTime
    
    /// 实际生成图片的时间
    public var actualTime: CMTime
    
    /// 初始化方法
    public init(image: UIImage, requestedTime: CMTime, actualTime: CMTime) {
        self.image = image
        self.requestedTime = requestedTime
        self.actualTime = actualTime
    }
}

/// 生成单张图片时需要传递的闭包类型
public typealias SingleImageClosure = (KeyframeImage?) -> Void
/// 生成多张图片时需要传递的闭包类型
public typealias SequenceOfImagesClosure = ([KeyframeImage]) -> Void

/// 生成关键帧图片
open class KeyframeImageGenerator: NSObject {
    
    /// 生成某个时间点的单张图片
    ///
    /// - parameter asset:   AVAsset
    /// - parameter time:    将要生成图片的时间，默认为0即取视频第一帧
    /// - parameter closure: 图片生成完成后会执行该闭包回调
    open func generateSingleImage(from asset: AVAsset, time: Float64 = 0, closure: @escaping SingleImageClosure) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        //如果不设置这两个属性为kCMTimeZero，则实际生成的图片和需要生成的图片会有时间差
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        
        imageGenerator.appliesPreferredTrackTransform = true
        
        let requestedTime = CMTimeMakeWithSeconds(time, asset.duration.timescale)
        var actualTime: CMTime = CMTimeMake(0, asset.duration.timescale)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: requestedTime, actualTime: &actualTime)
            let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
            let keyframeImage = KeyframeImage(image: image, requestedTime: requestedTime, actualTime: actualTime)
            
            //主线程回调
            DispatchQueue.main.async {
                closure(keyframeImage)
            }
        } catch {
            
            //主线程回调
            DispatchQueue.main.async {
                closure(nil)
            }
        }
    }
    
    /// 生成多个时间点的多张图片
    ///
    /// - parameter asset:   AVAsset
    /// - parameter times:   时间点集合
    /// - parameter closure: 图片生成完成后会执行该闭包回调，该闭包参数为按时间排序的数组
    open func generateSequenceOfImages(from asset: AVAsset, times: [Float64], closure: @escaping SequenceOfImagesClosure) {
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        //如果不设置这两个属性为kCMTimeZero，则实际生成的图片和需要生成的图片会有时间差
        imageGenerator.requestedTimeToleranceBefore = kCMTimeZero
        imageGenerator.requestedTimeToleranceAfter = kCMTimeZero
        
        imageGenerator.appliesPreferredTrackTransform = true
        
        let timeValues = times.map { CMTimeMakeWithSeconds($0, asset.duration.timescale) }
                              .map { NSValue(time: $0) }
        
        var keyframeImages: [KeyframeImage] = []
        //统计已完成生成图片的个数（无论失败或是成功都算完成）
        var completedCount = 0
        imageGenerator.generateCGImagesAsynchronously(forTimes: timeValues) {
            (requestedTime, cgImage, actualTime, result, error) in
            //每生成一张图片将已完成个数+1
            completedCount += 1
            
            if result == .succeeded, let cgImage = cgImage {
                let image = UIImage(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
                let keyframeImage = KeyframeImage(image: image, requestedTime: requestedTime, actualTime: actualTime)
                keyframeImages.append(keyframeImage)
            }
            
            //当已完成个数等于需要生成的个数时，代表所有图片均已生成完毕
            if completedCount == timeValues.count {
                //将所有生成的图片根据实际时间升序排序
                let sortedKeyframeImages = keyframeImages.sorted {
                    $0.actualTime.seconds < $1.actualTime.seconds
                }
                
                //主线程回调
                DispatchQueue.main.async {
                    closure(sortedKeyframeImages)
                }
            }
        }
    }
    
    /// 根据传入的AVAsset，生成默认一组图片(生成多少张图片的规则类似于系统相册)
    ///
    /// - parameter asset:   AVAsset
    /// - parameter closure: 图片生成完成后会执行该闭包回调，该闭包参数为按时间排序的数组
    open func generateDefaultSequenceOfImages(from asset: AVAsset, closure: @escaping SequenceOfImagesClosure) {
        // #warnning times is test value
        generateSequenceOfImages(from: asset, times: [0, 1, 2, 3, 4, 5], closure: closure)
    }
}
