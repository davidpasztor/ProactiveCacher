//
//  YouTubeVideoPlayerVC.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 24/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit
import WebKit

class YouTubeVideoPlayerVC: UIViewController {
    
    @IBOutlet weak var videoPlayerView: WKWebView!
    var videoURL:URL!
    var didLoadVideo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayerView.configuration.mediaTypesRequiringUserActionForPlayback = []
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Size of the webView is used to size the YT player frame in the JS code and the size of the webView is only known in `viewDidLayoutSubviews`, however, this function is called again once the HTML is loaded, so need to store a bool indicating whether the HTML has already been loaded once
        /*
        print("videoPlayerView size: \(videoPlayerView.frame.width)x\(videoPlayerView.frame.height)")
        print("screen bounds: \(UIScreen.main.bounds)")
        print("screen native bounds: \(UIScreen.main.nativeBounds)")
        print("screen native scale: \(UIScreen.main.nativeScale)")
         */
        if !didLoadVideo {
            videoPlayerView.loadHTMLString(embedVideoHtml, baseURL: nil)
            didLoadVideo = true
        }
    }
    
    var embedVideoHtml:String {
        return """
        <!DOCTYPE html>
        <html>
        <body>
        <!-- 1. The <iframe> (and video player) will replace this <div> tag. -->
        <div id="player"></div>
        
        <script>
        var tag = document.createElement('script');
        
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
        
        var player;
        function onYouTubeIframeAPIReady() {
        player = new YT.Player('player', {
        height: '\(videoPlayerView.frame.height*UIScreen.main.nativeScale)',
        width: '\(videoPlayerView.frame.width*UIScreen.main.nativeScale)',
        videoId: '\(videoURL.lastPathComponent)',
        events: {
        'onReady': onPlayerReady
        }
        });
        }
        
        function onPlayerReady(event) {
        event.target.playVideo();
        }
        </script>
        </body>
        </html>
        """
    }
}
