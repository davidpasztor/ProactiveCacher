//
//  StreamedVideoVC.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 04/03/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit
import WebKit

class StreamedVideoVC: UIViewController {

    @IBOutlet weak var videoPlayerView: WKWebView!
    
    var streamHtmlString:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let streamHtmlString = streamHtmlString {
            videoPlayerView.loadHTMLString(streamHtmlString, baseURL: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
