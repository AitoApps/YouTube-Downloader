//
//  YouTubeDownloader.swift
//  Pods
//
//  Created by Charlton Business on 12/28/16.
//
//

import Foundation
import TFHpple

final class YouTubeScraper {
    
    public class func getDirectLink(fromPageSource source: String) -> URL? {
        
        if let string = getVideoAttribute(forKey: "src", source: source) as? String {
            if let url = URL(string: string) {
                return url
            }
        }
        return nil
    }
    
    public class func getVideoTitle(fromPageSource source: String) -> String? {
        if let string = getVideoAttribute(forKey: "title", source: source) as? String {
            return string
        }
        return nil
    }
    
    public class func getThumbnailImage(fromPageSource source: String) -> UIImage? {
        let parser = TFHpple(htmlData: source.data(using: .utf8, allowLossyConversion: false))!
        if let elements = parser.search(withXPathQuery: "//div[@class='_muv _mne']") {
            for el in elements {
                if var string = (el as! TFHppleElement).attributes["style"] as? String {
                    string = string.replacingOccurrences(of: "background-image: url(", with: "")
                    string = string.replacingOccurrences(of: ");", with: "")
                    if let url = URL(string: string) {
                        if let data = try? Data(contentsOf: url) {                        
                            return UIImage(data: data)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    private class func getVideoAttribute(forKey key: String, source: String) -> Any? {
        let parser = TFHpple(htmlData: source.data(using: .utf8, allowLossyConversion: false))!
        if let videos = parser.search(withXPathQuery: "//video") {
            for video in videos {
                if let string = (video as! TFHppleElement).attributes[key] as? String {
                    return string
                }
            }
        }
        return nil
    }
   
}
