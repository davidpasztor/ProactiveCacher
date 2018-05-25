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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayerView.navigationDelegate = self
        //videoPlayerView.configuration.allowsInlineMediaPlayback = true
        videoPlayerView.configuration.mediaTypesRequiringUserActionForPlayback = []
        videoPlayerView.load(URLRequest(url: videoURL))
        videoPlayerView.loadHTMLString(embedVideoHtml, baseURL: nil)
        print(videoURL.lastPathComponent)
    }
    
    var embedVideoHtml:String {
        return """
        <!DOCTYPE html>
        <html>
        <body>
        <!-- 1. The <iframe> (and video player) will replace this <div> tag. -->
        <div id="player"></div>
        
        <script>
        // 2. This code loads the IFrame Player API code asynchronously.
        var tag = document.createElement('script');
        
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
        
        // 3. This function creates an <iframe> (and YouTube player)
        //    after the API code downloads.
        var player;
        function onYouTubeIframeAPIReady() {
        player = new YT.Player('player', {
        height: '\(videoPlayerView.frame.height)',
        width: '\(videoPlayerView.frame.width)',
        videoId: '\(videoURL.lastPathComponent)',
        events: {
        'onReady': onPlayerReady
        }
        });
        }
        
        // 4. The API will call this function when the video player is ready.
        function onPlayerReady(event) {
        event.target.playVideo();
        }
        </script>
        </body>
        </html>
        """
    }
}

extension YouTubeVideoPlayerVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        /*
        webView.evaluateJavaScript("player.playVideo()", completionHandler: { (result, error) in
            print(result ?? "No result from player.playVideo()")
            print(error ?? "No error")
        })
         */
    }
}
