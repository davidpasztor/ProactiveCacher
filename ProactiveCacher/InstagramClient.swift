//
//  InstagramClient.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 27/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import Foundation
import PromiseKit
import PMKCoreLocation

class InstagramClient {
    
    static let shared = InstagramClient()
    private init(){}
    
    let clientID = "518044a832694c54bacb7c2375a9ff5f"
    let redirectURI = "https://proactivecacher.co.uk/instagram"
    var instagramAuthURL:URL {
        return URL(string: "https://api.instagram.com/oauth/authorize/?client_id=\(clientID)&redirect_uri=\(redirectURI)&response_type=token")!
    }
    var accessToken:String? {
        return UserDefaults.standard.value(forKey: "InstagramAccessToken") as? String
    }
    
    func login(){
        
    }
    
    func getMediaAroundUserLocation()->Promise<Void>{
        return Promise{ fulfill, reject in
            if let accessToken = self.accessToken {
                CLLocationManager.promise().then{ userLoc->Void in
                    let urlString = "https://api.instagram.com/v1/media/search?lat=\(userLoc.coordinate.latitude)&lng=\(userLoc.coordinate.longitude)&access_token=\(accessToken)"
                    print(urlString)
                    guard let url = URL(string: urlString) else {
                        reject(AppErrors.InvalidURL(urlString)); return
                    }
                    URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                        guard let data = data, error == nil else {
                            reject(error ?? AppErrors.Unknown);return
                        }
                        do {
                            let responseJSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                            print("JSON as dictionary:\n",responseJSON as? [String:Any])
                            print("JSON as array:\n",responseJSON as? [[String:Any]])
                        } catch {
                            //print(response)
                            reject(error); return
                        }
                        guard let responseJSON = (try? JSONSerialization.jsonObject(with: data)) as? [String:Any] else {
                            reject(AppErrors.JSONError); return
                        }
                        print(responseJSON)
                    }).resume()
                }
            } else {
                //Login needed
                reject(AppErrors.InstagramErrors.InvalidToken)
            }
        }
    }
}
