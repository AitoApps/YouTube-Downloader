//
//  VideoList.swift
//  YouTubeVideoDownloader
//
//  Created by Charlton Provatas on 1/1/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import AVFoundation

class VideoList : UIViewController {
    
    fileprivate var videos: [String] = []
    
    @IBOutlet weak var videoTable: UITableView! {
        didSet {
            videoTable.delegate = self
            videoTable.dataSource = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        appendWithoutAddingDuplicates(videos: try! FileManager.default.contentsOfDirectory(atPath: Literals.rootDirectory.path))
        videoTable.reloadData()
    }
    
    fileprivate func appendWithoutAddingDuplicates(videos: [String]) {
        for video in videos {
            if !contains(video: video) {
                self.videos.append(video)
            }
        }
    }
    
    fileprivate func contains(video: String) -> Bool {
        for theVideo in self.videos {
            if video == theVideo {
                return true
            }
        }
        return video == ".DS_Store"
    }
}

extension VideoList : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView.cellForRow(at: indexPath) as! VideoCell).progressBar.isHidden {
            initVideoPlayer(videos[indexPath.row])
        }else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    private func initVideoPlayer(_ name: String) {
        let url = Literals.rootDirectory.appendingPathComponent(name)
        let player = AVPlayerViewController()
        player.player = AVPlayer(url: url)
        present(player, animated: true) { 
            player.player!.play()
        }
    }
}

extension VideoList : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Place Holder Foo"
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do {
                try FileManager.default.removeItem(at: Literals.rootDirectory.appendingPathComponent(videos[indexPath.row]))
                videos.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .left)
            }catch {
                UIAlertView(title: "Error", message: "Couldn't Delete File", delegate: nil, cancelButtonTitle: "OK")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = UIColor.red        
        let l = UILabel(frame: CGRect(x: view.center.x - 100, y: 3.5, width: 200, height: 20))
        l.textAlignment = .center
        l.text = "Your Downloads"
        l.font = UIFont(name: "Avenir", size: (isIpad ? 30 : 18))
        l.textColor = UIColor.white
        v.addSubview(l)
        return v
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell") as! VideoCell
        let video = videos[indexPath.row]
        cell.textLabel!.text = video
        
        if FileManager.default.fileExists(atPath: Literals.rootDirectory.appendingPathComponent(video).path) {
            cell.downloadedState()
        }else {
            cell.downloadState()
        }
        
        return cell
    }
}

extension VideoList : YouTubeViewerDelegate {
    
    func downloadDidBegin(name: String) {
        if index(forVideoName: name) == nil {
            appendWithoutAddingDuplicates(videos: [name])
            if videoTable == nil {
                setUp()
            }
            
            videoTable.reloadData()
            if let cell = videoTable.cellForRow(at: IndexPath(row: videos.count - 1, section: 0)) as? VideoCell {
                cell.downloadState()
            }
        }
    }
    
    func didReturnCurrentDownload(progress: Double, _ name: String) {
        if let index = index(forVideoName: name) {
            if let cell = videoTable.cellForRow(at: IndexPath(row: index, section: 0)) as? VideoCell {
                cell.progressBar.progress = Float(progress)
                cell.percentageLabel.text = "\(Int(Double(round(100 * progress) / 100) * 100))%"
                if progress == 1.0 {
                    cell.percentageLabel.text = "Done"
                    perform(#selector(fadeOut(cell:)), with: cell, afterDelay: 0.5)
                    cell.progressBar.isHidden = true
                }
            }
        }
        
    }
    
    @objc private func fadeOut(cell: VideoCell) {
        UIView.animate(withDuration: 0.4, animations: { 
            cell.percentageLabel.alpha = 0
        }) { (_) in
            cell.downloadedState()
        }
    }
    
    private func index(forVideoName name: String) -> Int? {
        
        for var i in 0..<videos.count {
            if videos[i] == name {
                return i
            }
        }
        return nil
    }
}

class VideoCell : UITableViewCell {
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var percentageLabel: UILabel!
    
    public func downloadState() {
        textLabel!.alpha = 0.4
        percentageLabel.isHidden = false
        progressBar.isHidden = false
    }
    
    public func downloadedState() {
        percentageLabel.isHidden = true
        progressBar.isHidden = true
        textLabel!.alpha = 1
    }
}
