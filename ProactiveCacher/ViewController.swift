//
//  ViewController.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import UIKit
import PromiseKit
import PMKCoreLocation
import RealmSwift
import BoxContentSDK

class ViewController: UIViewController {
    
    @IBAction func saveUserLocation() {
        let logger = UserDataLogger.shared
        logger.saveUserLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let logger = UserDataLogger.shared
        logger.getDownloadSpeed().then{ speed in
            print("Download speed is \(speed) kB/s")
            }.catch{ error in
                print(error.localizedDescription)
        }
        let realm = try! Realm()
        if let batteryLog = logger.getBatteryState() {
            print("Battery is at \(batteryLog.batteryPercentage)%, state: \(batteryLog.batteryState)")
            realm.save(object: batteryLog)
        }
        logger.saveUserLocation()
        print(logger.determineNetworkType().rawValue)
        print("Signal strength: \(logger.getSignalStrength() ?? -1)")
        
        if let jwtToken = BoxAPI.shared.generateJWTToken(isEnterprise: false, userId: BoxAPI.shared.sharedUserId) {
            BoxAPI.shared.getOAuth2Token(using: jwtToken, completion: { oAuthToken, expiryDate, error in
                guard let oAuthToken = oAuthToken, let expiryDate = expiryDate, error == nil else {
                    print(error?.localizedDescription ?? "No error");return
                }
                print("OAuthToken: \(oAuthToken), expires at : \(expiryDate)")
                BoxAPI.shared.accessToken = oAuthToken
                BoxAPI.shared.getFolderInfo(completion: { fileIDs, error in
                    guard let fileIDs = fileIDs, error == nil else {
                        print(error!);return
                    }
                    print(fileIDs)
                    BoxAPI.shared.createThumbnail(for: fileIDs.first!.id, completion: { thumbnail, error in
                        guard let thumbnail = thumbnail else {
                            print(error!); return
                        }
                        DispatchQueue.main.async {
                            let thumbnailView = UIImageView(frame: self.view.frame)
                            thumbnailView.image = thumbnail
                            self.view.addSubview(thumbnailView)
                        }
                    })
                })
            })
        } else {
            print("No JWT token")
        }
    }


}
