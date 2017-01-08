//
//  AVPlayerBlocker.swift
//  YouTubeVideoDownloader
//
//  Created by Charlton Provatas on 1/2/17.
//  Copyright © 2017 Charlton Provatas. All rights reserved.
//

import Foundation
import UIKit


class AVPlayerBlocker : NSObject {
        
    public func blockAvPlayer() {
        UIApplication.shared.windows[0].makeKeyAndVisible()        
        perform(#selector(searchForAndDismissFullScreen), with: nil, afterDelay: 0.6)
    }
    
    @objc private func searchForAndDismissFullScreen() {
        if UIApplication.shared.windows.count < 2 { return }        
        for subview in UIApplication.shared.windows[1].subviews {
            subview.searchForAndTapFullScreen()
        }
    }
}


fileprivate extension UIView {
    func searchForAndTapFullScreen() {
        for subview in subviews {
            if String(describing: subview).contains("AVButton") {
                (subview as! UIButton).sendActions(for: .touchUpInside)
            }
            subview.searchForAndTapFullScreen()
        }
    }
}
