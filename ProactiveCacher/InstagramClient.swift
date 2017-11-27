//
//  InstagramClient.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 27/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import Foundation

class InstagramClient {
    
    static let shared = InstagramClient()
    private init(){}
    
    let clientId = "518044a832694c54bacb7c2375a9ff5f"
    let redirectURI = "https://proactivecacher.co.uk/instagram"
    var instagramAuthURL:URL {
        return URL(string: "https://api.instagram.com/oauth/authorize/?client_id=\(clientId)&redirect_uri=\(redirectURI)&response_type=token")!
    }
}
