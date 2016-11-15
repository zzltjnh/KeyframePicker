//
//  KeyframePickerCursorViewController.swift
//  KeyframePicker
//
//  Created by zhangzhilong on 2016/11/15.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit

private let animationDuration = 0.3

class KeyframePickerCursorViewController: UIViewController {

    //MARK: - IBOutlets
    @IBOutlet weak var timeContainerView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    //MARK: - Public Properties
    public var seconds: Double = 0 {
        didSet {
            updateUI()
        }
    }
    
    //MARK: - Private Properties
    private var _seconds: Int {
        //小数点后一位四舍五入
        if Int(seconds * 10) % 10 >= 5 {
            return Int(seconds) + 1
        }
        return Int(seconds)
    }
    
    private var _timeString: String {
        //时
        var hourString = ""
        let hour = _seconds / 3600
        if hour > 0 {
            hourString = "\(hour):"
        }
        
        //分
        var minuteString = ""
        let minute = _seconds % 3600 / 60
        if hour > 0, minute < 10 {
            minuteString = "0\(minute):"
        } else {
            minuteString = "\(minute):"
        }
        
        //秒
        let sec = _seconds % 60
        var secondsString = ""
        if sec < 10 {
            secondsString = "0\(sec)"
        } else {
            secondsString = "\(sec)"
        }
        
        return hourString + minuteString + secondsString
    }
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - UI Related
    public func showTimeView() {
        self.timeContainerView.isHidden = false
        UIView.animate(withDuration: animationDuration) {
            self.timeContainerView.alpha = 1
        }
    }
    
    public func  hiddenTimeView() {
        UIView.animate(withDuration: animationDuration,
                       animations: {
                        self.timeContainerView.alpha = 0
                        }) {
                            if $0 {
                                self.timeContainerView.isHidden = true
                            }
        }
    }
    
    private func configUI() {
        timeContainerView.layer.cornerRadius = 2
    }
    
    private func updateUI() {
        timeLabel.text = _timeString
    }

}
