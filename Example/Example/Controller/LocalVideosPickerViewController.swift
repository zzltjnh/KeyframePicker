//
//  LocalVideosPickerViewController.swift
//  Example
//
//  Created by zhangzhilong on 2016/11/11.
//  Copyright © 2016年 zhangzhilong. All rights reserved.
//

import UIKit
import KeyframePicker

private let reuseIdentifier = "Cell"
private let VideoDirectoryName = "Videos"

class LocalVideosPickerViewController: UIViewController {
    
    var videos: [VideoModel] = []
    
    @IBOutlet weak var tableView: UITableView!
    
    // Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Local Video"
        
        loadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Load Video Datas
    func loadData() {
        // get videos directory path
        let videosDirectoryPath = Bundle.main.bundlePath.appending("/" + VideoDirectoryName + "/")
        do {
            // get all file in videosDirectoryPath
            let contents = try FileManager.default.contentsOfDirectory(atPath: videosDirectoryPath)
            
            let _videos = contents.map { (fileName) -> VideoModel in
                var videoModel = VideoModel()
                videoModel.videoName = fileName
                videoModel.videoPath = videosDirectoryPath + fileName
                
                return videoModel
            }
            
            videos.append(contentsOf: _videos)
            
            tableView.reloadData()
            print("read videos success from main bundle")
        } catch {
            print("read videos failed from main bundle")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier ==  String(describing: KeyframeImageDisplayViewController.self) {
            let vc = segue.destination as! KeyframeImageDisplayViewController
            vc.image = sender as? KeyframeImage
        }
    }
}

extension LocalVideosPickerViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let videoModel = videos[indexPath.row]
        cell.textLabel?.text = videoModel.videoName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoModel = videos[indexPath.row]
        guard let videoPath = videoModel.videoPath else { return }
        
        let storyBoard = UIStoryboard(name: "KeyframePicker", bundle: Bundle(for: KeyframePickerViewController.self))
        let keyframePicker = storyBoard.instantiateViewController(withIdentifier: String(describing: KeyframePickerViewController.self)) as! KeyframePickerViewController
        
        keyframePicker.videoPath = videoPath
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
        
        navigationController?.pushViewController(keyframePicker, animated: true)
    }
}
