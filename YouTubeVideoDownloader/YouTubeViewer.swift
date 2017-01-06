//
//  ViewController.swift
//  YouTubeVideoDownloader
//
//  Created by Charlton Provatas on 1/1/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import UIKit
import WebKit
import Alamofire

//       - Prevent AutoPlaying in YouTube
//       - Perhaps Figure out how to hide the download button? 

public struct Literals {
    static let rootDirectory = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
}

protocol YouTubeViewerDelegate {
    func downloadDidBegin(name: String)
    func didReturnCurrentDownload(progress: Double, _ name: String)
}

class YouTubeViewer: UIViewController {
    
    public var delegate: YouTubeViewerDelegate?
    
    fileprivate var webView: WKWebView! =  {
        let theWebView = WKWebView()
        theWebView.load(URLRequest(url: URL(string: "https://m.youtube.com/")!))
        return theWebView
    }()
    
    fileprivate let downloadButton: UIButton! = {
        let download = UIButton(type: .roundedRect)
        download.backgroundColor = UIColor.black
        download.setTitle("Download Video", for: .normal)
        download.setTitleColor(UIColor.white, for: .normal)
        return download
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let f = view.frame
        webView.frame = CGRect(x: f.origin.x, y: f.origin.y, width: f.size.width, height: f.size.height - (f.size.height * 0.13))
        downloadButton.frame = CGRect(x: 0, y: webView.frame.size.height, width: f.size.width, height: (f.size.height * 0.13) - tabBarController!.tabBar.frame.size.height)
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        webView.navigationDelegate = self
        view.addSubview(webView)
        view.addSubview(downloadButton)
        NotificationCenter.default.addObserver(self, selector: #selector(blockAvPlayerViewControllerAutoPlay), name: .UIWindowDidResignKey, object: nil)
    }
    
    @objc private func blockAvPlayerViewControllerAutoPlay() {
        if UIApplication.shared.windows.count > 1 && UIApplication.shared.windows[1].isHidden == false {
            AVPlayerBlocker.defaultBlocker.blockAvPlayer() //prevent AVPlayerFrom AutoPlaying
        }
    }
    
    @objc private func downloadTapped() {
        if webView.url != nil && webView.url!.absoluteString.contains("watch?v=") {
            YouTubeDownloader.getDirectLink(fromYoutubeUrl: webView.url!, completionHandler: { (url) in
                if url != nil {
                    self.initDownload(url: url!)
                }else {
                    print("Couldn't fetch link")
                }
            })
        }else {
            UIAlertView(title: "Error", message: "Please click on a YouTube Video before trying to download.", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }

    private func initDownload(url: URL) {
        let path = Literals.rootDirectory.appendingPathComponent("video\(arc4random_uniform(1000000)).mp4")
        delegate?.downloadDidBegin(name: path.lastPathComponent)
        print(path)
        Alamofire.download(url, method: .get, encoding: URLEncoding.default) { (destroy_stage, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                return (destinationURL: path, options: DownloadRequest.DownloadOptions.removePreviousFile)
            }.downloadProgress { (progress) in
                self.delegate?.didReturnCurrentDownload(progress: progress.fractionCompleted, path.lastPathComponent)
            }
    }
    
}

extension YouTubeViewer : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
}

