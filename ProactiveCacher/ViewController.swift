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
import PMKCoreLocation
import SwiftInstagram
import RealmSwift

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
        logger.determineNetworkType()
        print("Signal strength: \(logger.getSignalStrength() ?? -1)")
        let instagramClient = InstagramClient.shared
        if instagramClient.accessToken == nil {
            let instagramLoginVC = InstagramLoginViewController(clientID: instagramClient.clientID, redirectURI: instagramClient.redirectURI) { accessToken, error in
                guard let accessToken = accessToken else {
                    print("Failed login: " + error!.localizedDescription)
                    return
                }
                self.navigationController?.popViewController(animated: true)
                print("Successful login to Instagram, accessToken: \(accessToken)")
                UserDefaults.standard.set(accessToken, forKey: "InstagramAccessToken")
            }
            instagramLoginVC.scopes = [.basic, .publicContent]
            show(instagramLoginVC, sender: self)
        } else { //Already logged in
            instagramClient.getMediaAroundUserLocation().then{ _->Void in
                
            }.catch{ error in
                print(error)
            }
        }
        
        /*
        let instagramAPI = Instagram.shared
        instagramAPI.login(from: self.navigationController!,withScopes: [.publicContent], success: {
            print("Successful login to Instagram!")
            instagramAPI.recentMedia(fromUser: "self", success: { media in
                guard let image = media.first?.images.standardResolution else {
                    print("Couldn't find first image of own user"); return
                }
                URLSession.shared.dataTask(with: image.url, completionHandler: { data, response, error in
                    guard let data = data, error == nil else {
                        print("Error downloading image from Instagram \(error?.localizedDescription ?? "")"); return
                    }
                    print("Image successfully downloaded")
                    guard let downloadedImage = UIImage(data: data) else {
                        print("Couldn't create UIImage"); return
                    }
                    let imageView = UIImageView(frame: CGRect(x: 50, y: 50, width: image.width, height: image.height))
                    imageView.image = downloadedImage
                    self.view.addSubview(imageView)
                })
            }, failure: { error in
                print("Couldn't retrieve own media \(error)")
            })
            /*
            CLLocationManager.promise().then{ currentLocation in
                instagramAPI.searchMedia(lat: currentLocation.coordinate.latitude, lng: currentLocation.coordinate.longitude, distance: 5, success: { media in
                    guard let image = media.first?.images else {
                        print("No image URL"); return
                    }
                    URLSession.shared.dataTask(with: image.standardResolution.url, completionHandler: { data, response, error in
                        guard let data = data, error == nil else {
                            print("Error downloading image from Instagram \(error?.localizedDescription ?? "")"); return
                        }
                        print("Image successfully downloaded")
                        guard let downloadedImage = UIImage(data: data) else {
                            print("Couldn't create UIImage"); return
                        }
                        let imageView = UIImageView(frame: CGRect(x: 50, y: 50, width: image.standardResolution.width, height: image.standardResolution.height))
                        imageView.image = downloadedImage
                        self.view.addSubview(imageView)
                    })
                }, failure: { error in
                    print("Couldn't retrieve media around current location \(error)")
                })
            }
            */
        }, failure: { error in
            print("Couldn't log in to Instagram: \(error.localizedDescription)")
        })
        */
    }


}
