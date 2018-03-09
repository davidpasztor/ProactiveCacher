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
    @objc dynamic var timeStamp = Date()    // Kept in schemaVersion 3, will be deleted in schemaVersion 4
}

class UserLog: Object {
    @objc private dynamic var _networkStatus = ""
    @objc dynamic var location: UserLocation?
    @objc dynamic var batteryState: BatteryStateLog?
    @objc dynamic var downloadSpeed:Double = 0
    // Make _timeStamp a private backing variable, since we want to make it immutable, but Realm properties must be mutable
    @objc private dynamic var _timeStamp = Date()
    // Only used as a primaryKey, since a Date object can't be a primary key, so it's safe to make it private, closure initialization is needed since the value is the result of a function call, DateFormatter.string(from:)
    @objc private dynamic var _timeStampString: String = {
        return ISO8601DateFormatter().string(from: Date())
    }()
    
    // Realm can't store enum values, so need this ignored property to back the private _networkStatus variable
    var networkStatus: Reachability.Connection {
        get {
            return Reachability.Connection(description: _networkStatus)
        }
        set(newValue) {
            _networkStatus = newValue.description
        }
    }
    
    var timeStamp:Date {
        return _timeStamp
    }
    
    override class func primaryKey()->String {
        return "_timeStampString"
    }
}

class Video: Object, Decodable {
    @objc dynamic var youtubeID = ""
    @objc dynamic var title = ""
    @objc dynamic var filePath:String? = nil
    @objc dynamic var thumbnailPath:String? = nil
    @objc dynamic var watched = false
    let rating = RealmOptional<Double>()
    
    override class func primaryKey()->String {
        return "youtubeID"
    }
    
    private enum CodingKeys: String, CodingKey {
        case youtubeID, title, filePath, thumbnailPath, watched, rating
    }
    
    convenience required init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.youtubeID = try container.decode(String.self, forKey: .youtubeID)
        self.title = try container.decode(String.self, forKey: .title)
        // Video can't be saved at the device when it's decoded
        self.filePath = nil
        self.thumbnailPath = nil
        // These might not come from the response
        do {
            self.watched = try container.decode(Bool.self, forKey: .watched)
            self.rating.value = try container.decode(Double.self, forKey: .rating)
        } catch {
        }
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
