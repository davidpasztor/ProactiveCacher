//
//  ShareViewController.swift
//  VideoSharingExtension
//
//  Created by Pásztor Dávid on 02/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        print("contentText: \(self.contentText)")
        //contentText is in the form: https://www.youtube.com/watch?v=-DRsfNObKIQ&feature=share
        // Need to validate the URL is a valid YouTubeURL
        return URLValidator.validateYouTubeURL(urlString: self.contentText)
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
        print("contentText: \(self.contentText)")
        print("Input items: \(self.extensionContext?.inputItems ?? ["No items"])")
        //contentText is in the form: https://www.youtube.com/watch?v=-DRsfNObKIQ&feature=share
        // Need to trim the end (feature=share)
        CacheServerAPI.shared.uploadVideo(with: URL(string: self.contentText)!, completion: { result in
            switch result {
            case let .failure(error):
                print(error)
            case .success(_):
                print("YouTube video successfully uploaded using Share Extension")
            }
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        })
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        //self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
