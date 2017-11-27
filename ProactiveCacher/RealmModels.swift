//
//  RealmModels.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import Foundation
import RealmSwift

class BatteryStateLog: Object {
    @objc dynamic var batteryPercentage:Float = 0
    @objc dynamic var batteryState = ""
}

class UserLocation: Object {
    @objc dynamic var latitude:Double = 0
    @objc dynamic var longitude:Double = 0
    @objc dynamic var timeStamp = Date()
}

class UserLog: Object {
    @objc dynamic var networkStatus = ""
    @objc dynamic var location: UserLocation?
    @objc dynamic var batteryState: BatteryStateLog?
    @objc dynamic var downloadSpeed:Double = 0
    @objc dynamic var signalStrength:Double = 0
    
    enum NetworkStatus:String{
        case Wifi, Mobile, Offline
    }
}
