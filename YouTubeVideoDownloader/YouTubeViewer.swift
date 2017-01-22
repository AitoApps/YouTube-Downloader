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
    func downloadDidBegin(name: String, url: URL)
    func didReturnCurrentDownload(progress: Double, _ name: String)
}

class YouTubeViewer: UIViewController {
    
    public var delegate: YouTubeViewerDelegate?
    
    @objc fileprivate var webView: WKWebView! =  {
        let theWebView = WKWebView()
        theWebView.load(URLRequest(url: URL(string: "https://m.youtube.com/")!))
        return theWebView
    }()
    
    fileprivate let downloadButton: WKButton! = {
        let download = WKButton(type: .roundedRect)
        download.backgroundColor = .red
        download.setTitle("Download Video", for: .normal)
        download.setTitleColor(UIColor.white, for: .normal)
        UI.addShadow(download)
        return download
    }()
    
    fileprivate let activityIndicator: UIActivityIndicatorView! = {
         let a = UIActivityIndicatorView(frame: UIScreen.main.bounds)
         a.activityIndicatorViewStyle = .whiteLarge
         a.startAnimating()
         a.color = .black
         return a
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let f = view.frame
        webView.frame = CGRect(x: f.origin.x, y: f.origin.y, width: f.size.width, height: f.size.height - tabBarController!.tabBar.frame.size.height)
        webView.navigationDelegate = self
        downloadButton.defaultFrame = CGRect(x: (f.size.width * 0.635) - 5, y: webView.frame.size.height -  (f.size.height * 0.065) - 5, width: f.size.width * 0.375, height: (f.size.height * 0.15) - tabBarController!.tabBar.frame.size.height)
        downloadButton.frame = downloadButton.defaultFrame
        downloadButton.frame.origin.y = UIScreen.main.bounds.size.height
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        downloadButton.layer.cornerRadius = 10
        webView.navigationDelegate = self
        view.addSubview(webView)
        view.addSubview(downloadButton)
        view.addSubview(activityIndicator)
        NotificationCenter.default.addObserver(self, selector: #selector(blockAvPlayerViewControllerAutoPlay), name: .UIWindowDidResignKey, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldShowButton), name: NSNotification.Name(rawValue: "shouldShowDownloadButton"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldHideButton), name: NSNotification.Name(rawValue: "shouldHideDownloadButton"), object: nil)
    }
    
    @objc private func shouldShowButton() {
        if downloadButton.isVisible { return }
        downloadButton.isVisible = true
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4) {
                self.downloadButton.frame = self.downloadButton.defaultFrame
            }
        }
    }
    
    @objc private func shouldHideButton() {        
        if !downloadButton.isVisible { return }
        downloadButton.isVisible = false
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4) {
                self.downloadButton.frame.origin.y = UIScreen.main.bounds.size.height
            }
        }
    }
    
    @objc private func blockAvPlayerViewControllerAutoPlay() {
        if UIApplication.shared.windows.count > 1 && UIApplication.shared.windows[1].isHidden == false {
            AVPlayerBlocker().blockAvPlayer() //prevent AVPlayerFrom AutoPlaying
        }
    }
    
    @objc private func downloadTapped() {
        if webView.url != nil && webView.url!.absoluteString.contains("watch?v=") {            
            webView.evaluateJavaScript("document.documentElement.outerHTML.toString()", completionHandler: { (html: Any?, error: Error?) in
                if html == nil { return }
                if let url = YouTubeScraper.getDirectLink(fromPageSource: html as! String) {
                    self.initDownload(url: url, name: YouTubeScraper.getVideoTitle(fromPageSource: html as! String), imgUrl: YouTubeScraper.getThumbnailImage(fromUrlString: self.webView.url!.absoluteString))
                }
            })
            
        }else {
            UIAlertView(title: "Error", message: "Please click on a YouTube Video before trying to download.", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }

    private func initDownload(url: URL, name: String?, imgUrl: URL) {
        let videoName = (name ?? "video\(arc4random_uniform(1000000))") + ".mp4" 
        let path = Literals.rootDirectory.appendingPathComponent(videoName)
        print(path)
        
        delegate?.downloadDidBegin(name: path.lastPathComponent, url: imgUrl)
        let notificationView = YTNotificationView(text: "Video has been added to downloads!")
        view.addSubview(notificationView)
        Alamofire.download(url, method: .get, encoding: URLEncoding.default) { (destroy_stage, response) -> (destinationURL: URL, options: DownloadRequest.DownloadOptions) in
                return (destinationURL: path, options: DownloadRequest.DownloadOptions.removePreviousFile)
            }.downloadProgress { (progress) in
                self.delegate?.didReturnCurrentDownload(progress: progress.fractionCompleted, path.lastPathComponent)
            }
        
    }
    
}

final class WKButton : UIButton {
    public var isVisible: Bool = false
    public var defaultFrame : CGRect = .zero
}

extension YouTubeViewer : WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.removeFromSuperview()
    }
}
