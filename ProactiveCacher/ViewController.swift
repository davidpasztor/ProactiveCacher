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
        /*
        if let jwtToken = BoxAPI.shared.generateJWTToken(isEnterprise: false, userId: BoxAPI.shared.sharedUserId) {
            BoxAPI.shared.getOAuth2Token(using: jwtToken, completion: { oAuthToken, expiryDate, error in
                guard let oAuthToken = oAuthToken, let expiryDate = expiryDate, error == nil else {
                    print(error?.localizedDescription ?? "No error");return
                }
                print("OAuthToken: \(oAuthToken), expires at : \(expiryDate)")
            })
        } else {
            print("No JWT token")
        }
        */
        BoxAPI.shared.client?.authenticate(completionBlock: { user, error in
            guard error == nil, let user = user else {
                print(error!);return
            }
            print(user)
            BOXContentClient(forUser: user).folderInfoRequest(withID: BOXAPIFolderIDRoot).perform(completion: { boxFolder, error in
                guard error == nil, let boxFolder = boxFolder else {
                    print(error!);return
                }
                print(boxFolder)
            })
        })
    }


}
