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
    @objc dynamic var batteryPercentage:Int = 0
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

class Video: Object, Decodable {
    @objc dynamic var youtubeID = ""
    @objc dynamic var title = ""
    @objc dynamic var filePath:String? = nil
    @objc dynamic var thumbnailPath:String? = nil
    
    override class func primaryKey()->String {
        return "youtubeID"
    }
}

extension Realm {
    func save<T:Object>(object:T){
        do {
            try self.write {
                self.add(object)
            }
        } catch {
            print(error)
        }
    }
    
    func saveOrUpdate<T:Object>(object:T, update: Bool = true){
        do {
            try self.write {
                self.add(object, update: update)
            }
        } catch {
            print(error)
        }
    }
}
