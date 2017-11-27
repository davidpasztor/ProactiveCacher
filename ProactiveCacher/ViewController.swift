//
//  ViewController.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import UIKit
import WebKit
import PromiseKit
import SwiftInstagram

class ViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    @IBAction func saveUserLocation() {
        let logger = UserDataLogger.shared
        logger.saveUserLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let instagramClient = InstagramClient.shared
//        webView.load(URLRequest(url: instagramClient.instagramAuthURL))
//        //webView.load(URLRequest(url: URL(string: "https://google.com")!))
//        webView.navigationDelegate = self
//        webView.uiDelegate = self
//        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let instagramAPI = Instagram.shared
        instagramAPI.login(from: self.navigationController!, success: {
            print("Successful login to Instagram!")
        }, failure: { error in
            print("Couldn't log in to Instagram: \(error.localizedDescription)")
        })
        let logger = UserDataLogger.shared
        logger.getDownloadSpeed().then{ speed in
            print("Download speed is \(speed) kB/s")
        }.catch{ error in
            print(error.localizedDescription)
        }
        logger.saveBatteryState()
    }


}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished navigating to: \(webView.url?.absoluteString ?? "No URL given")")
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Failed navigating to: \(webView.url?.absoluteString ?? "No URL given") with error: \(error)")
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let responseUrl = navigationResponse.response.url, let accessToken = responseUrl.pathComponents.first(where: {$0.contains("access_token")}) {
            print("Access token: \(accessToken)")
            decisionHandler(.allow)
        } else {
            print("No access token received \(navigationResponse.response.url)")
            decisionHandler(.allow)
        }
    }
}

extension ViewController: WKUIDelegate {
    
}
