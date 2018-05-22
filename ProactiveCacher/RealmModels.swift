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

class AppUsageLog: Object {
    static var current: AppUsageLog = {
        let realm = try! Realm()
        return realm.objects(AppUsageLog.self).sorted(byKeyPath: "_appOpeningTime", ascending: true).last!
    }()
    static var previous: Results<AppUsageLog> = {
        let realm = try! Realm()
        let current = AppUsageLog.current
        return realm.objects(AppUsageLog.self).filter("_appOpeningTime != %@", current._appOpeningTime)
    }()
    
    // Time of the user opening the app
    @objc private dynamic var _appOpeningTime = Date()
    @objc private dynamic var _appOpeningTimeString: String = {
        return ISO8601DateFormatter().string(from: Date())
    }()
    // Number of videos watched before quitting the app
    @objc dynamic var watchedVideosCount = 0
    // TODO: add a property that tracks how many of the watched videos were cached to use as an indicator of the caching efficiency
    
    var appOpeningTime:Date {
        return _appOpeningTime
    }
    
    override class func primaryKey() -> String {
        return "_appOpeningTimeString"
    }
}

extension AppUsageLog: Encodable {
    private enum CodingKeys: String, CodingKey {
        case appOpeningTime, watchedVideosCount
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_appOpeningTimeString, forKey: .appOpeningTime)
        try container.encode(watchedVideosCount, forKey: .watchedVideosCount)
    }
}

class BatteryStateLog: Object, Encodable {
    @objc dynamic var batteryPercentage:Int = 0
    @objc dynamic var batteryState = ""
}

class UserLocation: Object, Encodable {
    @objc dynamic var latitude:Double = 0
    @objc dynamic var longitude:Double = 0
}

class UserLog: Object {
    @objc private dynamic var _networkStatus = ""
    @objc dynamic var location: UserLocation?
    @objc dynamic var batteryState: BatteryStateLog?
    // Make _timeStamp a private backing variable, since we want to make it immutable, but Realm properties must be mutable
    @objc private dynamic var _timeStamp = Date()
    // Only used as a primaryKey, since a Date object can't be a primary key, so it's safe to make it private, closure initialization is needed since the value is the result of a function call, DateFormatter.string(from:)
    @objc private dynamic var _timeStampString: String = {
        return ISO8601DateFormatter().string(from: Date())
    }()
    @objc dynamic var syncedToBackend = false
    
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

extension UserLog: Encodable {
    private enum CodingKeys: String, CodingKey {
        case networkStatus, location, batteryState, timeStamp
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_networkStatus, forKey: .networkStatus)
        try container.encode(location, forKey: .location)
        try container.encode(batteryState, forKey: .batteryState)
        try container.encode(_timeStampString, forKey: .timeStamp)
    }
}

class Video: Object, Decodable {
    @objc dynamic var youtubeID = ""
    @objc dynamic var title = ""
    @objc dynamic var filePath:String? = nil
    @objc dynamic var thumbnailPath:String? = nil
    @objc dynamic var watched = false
    @objc dynamic var uploadDate = Date()
    let rating = RealmOptional<Double>()
    @objc dynamic var category: VideoCategory?
    
    var absoluteFileURL:URL? {
        if let filePath = filePath {
            return try? FileManager.default.videosDirectory().appendingPathComponent(filePath)
        } else {
            return nil
        }
    }
    
    var absoluteThumbnailURL:URL? {
        if let thumbnailPath = thumbnailPath {
            return try? FileManager.default.thumbnailsDirectory().appendingPathComponent(thumbnailPath)
        } else {
            return nil
        }
    }
    
    override class func primaryKey()->String {
        return "youtubeID"
    }
    
    private enum CodingKeys: String, CodingKey {
        case youtubeID, title, filePath, thumbnailPath, watched, rating, uploadDate, category
    }
    
    static let jsonDecoder: JSONDecoder = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    convenience required init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.youtubeID = try container.decode(String.self, forKey: .youtubeID)
        self.title = try container.decode(String.self, forKey: .title)
        self.uploadDate = try container.decode(Date.self, forKey: .uploadDate)
        // Video can't be saved at the device when it's decoded
        self.filePath = nil
        self.thumbnailPath = nil
        if let category = try container.decodeIfPresent(VideoCategory.self, forKey: .category) {
            self.category = category
        }
        // These might not come from the response
        do {
            self.watched = try container.decode(Bool.self, forKey: .watched)
            self.rating.value = try container.decode(Double.self, forKey: .rating)
        } catch {
        }
    }
}

class VideoCategory: Object, Decodable {
    @objc dynamic var name = ""
    @objc dynamic var id = ""
    let videos = LinkingObjects(fromType: Video.self, property: "category")
    
    override class func primaryKey()->String {
        return "id"
    }
    
    private enum CodingKeys: String, CodingKey {
        case name, id
    }
}

extension Realm {
    // TODO: improve the error handling here
    func save<T:Object>(object:T){
        do {
            try self.write {
                self.add(object)
            }
        } catch {
            print("Error creating Realm object, \(error)")
        }
    }
    
    func saveOrUpdate<T:Object>(object:T, update: Bool = true){
        do {
            try self.write {
                self.add(object, update: update)
            }
        } catch {
            print("Error \(update ? "updating" : "creating") Realm object, \(error)")
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
// Not used here at the moment, but doesn't seem to work in other projects (the init(from:) creates an empty list, the List elements are not added), also Decodable and Encodable conditional conformance should be separated since this conditional conformance only works for Codable classes, but doesn't work for De-/Encodable classes
extension List: Codable where List.Element: Codable {
    public convenience init(from decoder: Decoder) throws {
        self.init()
        var container = try decoder.unkeyedContainer()
        let array = try container.decode(Array<Element>.self)
        self.append(objectsIn: array)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(contentsOf: Array(self))
    }
}

extension FileManager {
    /**
     Get the document directory from the user domain mask. Be aware that the application directory changes on every app launch, so this shouldn't be used as part of persisted absolute URLs.
     */
    func documentDirectory() throws -> URL {
        return try self.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    /**
     Directory for storing Video thumbnails. Found at Application/sandboxID/Documents/thumbnails. If the directory doesn't exist yet, the function also creates it.
     */
    func thumbnailsDirectory() throws -> URL {
        let thumbnailsDirectory = try documentDirectory().appendingPathComponent("thumbnails", isDirectory: true)
        if !FileManager.default.fileExists(atPath: thumbnailsDirectory.path){
            try FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: false)
        }
        return thumbnailsDirectory
    }
    /**
     Directory for storing Videos. Found at Application/sandboxID/Documents/videos. If the directory doesn't exist yet, the function also creates it.
     */
    func videosDirectory() throws -> URL {
        let videosDirectory = try documentDirectory().appendingPathComponent("videos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: videosDirectory.path){
            try FileManager.default.createDirectory(at: videosDirectory, withIntermediateDirectories: false)
        }
        return videosDirectory
    }
}
