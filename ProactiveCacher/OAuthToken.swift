//
//  OAuthToken.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 08/02/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import Foundation

struct OAuthToken {
    private var _token:String
    var token:String? {
        get {
            //Token expired, return nil to signal that a new token needs to be created
            if expiryDate > Date() {
                return nil
            } else {
                return _token
            }
        }
        set {
            _token = newValue!
        }
    }
    var expiryDate:Date
}
