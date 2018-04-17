//
//  UserDataLogger.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import CoreLocation
import PromiseKit
import RealmSwift
import UIKit
import CoreTelephony
import Reachability

class UserDataLogger {
    static let shared = UserDataLogger()
    
    private init() {} //ensure no other instance can be created than the singleton
    
    lazy var realm = try! Realm()
    
    let reachability = Reachability()
    
    func saveUserLog(){
        let userLog = UserLog()
        userLog.batteryState = getBatteryState()
        CLLocationManager.promise().done { locations in
            if let location = locations.last {
                let locationLog = UserLocation()
                locationLog.latitude = location.coordinate.latitude
                locationLog.longitude = location.coordinate.longitude
                userLog.location = locationLog
            }
        }.ensure {
            if let connection = self.reachability?.connection {
                userLog.networkStatus = connection
                print("_networkStatus set to \(connection)")
            } else {
                print("_networkStatus set to default No connection")
            }
            print("Userlog saving, batteryState: \(userLog.batteryState?.batteryState ?? ""), percentage: \(userLog.batteryState?.batteryPercentage ?? 0), location: (\(userLog.location?.latitude ?? 0), \(userLog.location?.longitude ?? 0)), network: \(userLog.networkStatus) at \(userLog.timeStamp)")
            self.realm.saveOrUpdate(object: userLog)
        }.catch{ error in
            print("Cannot save UserLog: ",error)
        }
    }
    
    func saveUserLogWithoutLocation(){
        let userLog = UserLog()
        userLog.batteryState = getBatteryState()
        if let connection = self.reachability?.connection {
            userLog.networkStatus = connection
            print("_networkStatus set to \(connection)")
        } else {
            print("_networkStatus set to default No connection")
        }
        print("Userlog saving, batteryState: \(userLog.batteryState?.batteryState ?? ""), percentage: \(userLog.batteryState?.batteryPercentage ?? 0), network: \(userLog.networkStatus) at \(userLog.timeStamp)")
        self.realm.saveOrUpdate(object: userLog)
    }
    
    func saveUserLocation(){
        CLLocationManager.promise().done{ (locations:[CLLocation]) in
            guard let location = locations.last else {return}
            let lastLocation = UserLocation()
            lastLocation.latitude = location.coordinate.latitude
            lastLocation.latitude = location.coordinate.longitude
            self.realm.save(object: lastLocation)
            print("User location saved: (\(lastLocation.latitude),\(lastLocation.longitude))")
        }.catch { error in
            print("Cannot save userlocation",error)
        }
    }
    
    func getBatteryState()->BatteryStateLog?{
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLog = BatteryStateLog()
        batteryLog.batteryPercentage = Int(UIDevice.current.batteryLevel*100)
        switch UIDevice.current.batteryState {
        case .charging:
            batteryLog.batteryState = "charging"
        case .full:
            batteryLog.batteryState = "full"
        case .unknown:
            batteryLog.batteryState = "unknown"
        case .unplugged:
            batteryLog.batteryState = "unplugged"
        }
        guard batteryLog.batteryPercentage > 0 else {
            print("Couldn't retrieve battery percentage"); return nil
        }
        return batteryLog
    }
    
    //Return download speed in kilobytes/sec
    func getDownloadSpeed()->Promise<Double>{
        return Promise{ seal in
            let url = URL(string: "https://placehold.it/150/92c952")!
            let startDate = Date()
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                guard data != nil, error == nil, let response = response else {
                    seal.reject(error ?? AppErrors.DownloadSpeed.Generic); return
                }
                let expectedContentSize = response.expectedContentLength //content size in bytes
                guard expectedContentSize > 0 else {
                    seal.reject(AppErrors.DownloadSpeed.NoHeader); return
                }
                let responseTime = -startDate.timeIntervalSinceNow //download time in seconds
                seal.fulfill(Double(expectedContentSize)/1000/responseTime)
            }).resume()
        }
    }
    
    enum NetworkType:String {
        case LTE, UMTS, EDGE, Wifi, Offline
    }
    
    func determineNetworkType()->NetworkType{
        let networkType = CTTelephonyNetworkInfo().currentRadioAccessTechnology
        if let networkType = networkType {
            switch networkType {
            case CTRadioAccessTechnologyLTE:
                return NetworkType.LTE
            case CTRadioAccessTechnologyHSDPA, CTRadioAccessTechnologyHSUPA, CTRadioAccessTechnologyWCDMA:
                return NetworkType.UMTS
            case CTRadioAccessTechnologyGPRS, CTRadioAccessTechnologyEdge:
                return NetworkType.EDGE
            default:
                print("Unknown network type: \(networkType)")
                return NetworkType.Offline
            }
        }
        return NetworkType.Offline
    }
    
    func createAppAccessLog()->Result<Void>{
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(AppUsageLog())
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

enum AppErrors: Error {
    enum DownloadSpeed: String, LocalizedError {
        case NoHeader = "No content-length header in response"
        case Generic = "Can't measure download speed"
        
        var errorDescription: String? {
            return self.rawValue
        }
    }
    case InvalidURL(String)
    case Unknown
    case JSONError
    case FileError
}
