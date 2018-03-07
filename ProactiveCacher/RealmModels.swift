//
//  RealmModels.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import Foundation
import RealmSwift
import Reachability

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
    @objc private dynamic var _networkStatus = ""
    var location: UserLocation?
    var batteryState: BatteryStateLog?
    @objc dynamic var downloadSpeed:Double = 0
    
    var networkStatus: Reachability.Connection {
        get {
            return Reachability.Connection(description: _networkStatus)
        }
        set(newValue) {
            _networkStatus = newValue.description
        }
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

extension Reachability.Connection {
    init(description: String){
        switch description {
        case "Cellular":
            self = .cellular
        case "WiFi":
            self = .wifi
        default:
            self = .none
        }
    }
}
