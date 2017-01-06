//
//  YouTubeDownloader.swift
//  Pods
//
//  Created by Charlton Business on 12/28/16.
//
//

import Foundation
import TFHpple
import Alamofire

final class YouTubeDownloader {
    
    static private let DOWNLOAD_API = "http://keepvid.com/?url="
    
    
    public class func getDirectLink(fromYoutubeUrl url: URL, completionHandler: @escaping (URL?) -> ()) {
        
        getPageSource(url: url) { (string) in
            if let downloadLink = parsePageSourceForDownloadLink(string) {
                completionHandler(downloadLink)
            }else {
                completionHandler(nil)
                print("YouTubeDownloader: HTML Parser could not find a download link here :(")
            }
        }
        
    }
    
    private class func getPageSource(url: URL, completion: @escaping (String) -> ()) {
        
        if let validUrl = URL(string: DOWNLOAD_API + url.absoluteString) {            
            request(validUrl).responseString { (string) in
                if let result = string.result.value {
                    completion(result)
                }else {
                    print("YouTubeDownloader: Didn't get result from download request")
                }
            }
        }else {
            print("YouTubeDownloader: Attempted to fetch page source but is not a valid url")
        }
    }
    
    private class func parsePageSourceForDownloadLink(_ source: String) -> URL? {
        
        let parser = TFHpple(htmlData: source.data(using: .utf8, allowLossyConversion: false))!
        if let dInfoDiv = parser.search(withXPathQuery: "//div[@class='d-info2']") {
            if dInfoDiv.count > 0 {
                if let result = parseSectionDiv(dInfoDiv[0] as! TFHppleElement) {
                    return result
                }
            }
        }
        print("YouTubeDownloader: Couldn't parse the HTML, the html hierarchy may be different than what was in the initial testing environment")
        return nil
    }
    
    private class func parseSectionDiv(_ object: TFHppleElement) -> URL? {
        if let dlDivs = object.children(withTagName: "dl") {
            if dlDivs.count > 0 {
                if let ddSections = (dlDivs.first as! TFHppleElement).children(withTagName: "dd") {
                    if ddSections.count > 0 {
                        let firstDdSection = ddSections.first as! TFHppleElement
                        if let links = firstDdSection.children(withTagName: "a") {
                            if links.count > 0 {
                                return URL(string: ((links.first as! TFHppleElement)["href"] as! String))
                            }
                        }
                    }
                }
            }
        }
        return nil
    }
    
}
