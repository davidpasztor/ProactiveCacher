//
//  UserDataLogger.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import CoreLocation
import PMKCoreLocation
import PromiseKit
import RealmSwift
import UIKit
import CoreTelephony

class UserDataLogger {
    static let shared = UserDataLogger()
    
    private init() {} //ensure no other instance can be created than the singleton
    
    func saveUserLocation(){
        CLLocationManager.promise().then{ location->Void in
            let lastLocation = UserLocation()
            lastLocation.latitude = location.coordinate.latitude
            lastLocation.latitude = location.coordinate.longitude
            let realm = try! Realm()
            try! realm.write {
                realm.add(lastLocation)
            }
            print("User location saved: (\(lastLocation.latitude),\(lastLocation.longitude)) at \(lastLocation.timeStamp)")
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
        return Promise{ fulfill, reject in
            let url = URL(string: "https://placehold.it/150/92c952")!
            let startDate = Date()
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                guard data != nil, error == nil, let response = response else {
                    reject(error ?? AppErrors.DownloadSpeed.Generic); return
                }
                let expectedContentSize = response.expectedContentLength //content size in bytes
                guard expectedContentSize > 0 else {
                    reject(AppErrors.DownloadSpeed.NoHeader); return
                }
                let responseTime = -startDate.timeIntervalSinceNow //download time in seconds
                fulfill(Double(expectedContentSize)/1000/responseTime)
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
                return NetworkType.Offline
            }
        }
        return NetworkType.Offline
    }
    
    func getSignalStrength()->Int?{
        let libHandle = dlopen ("/System/Library/Frameworks/CoreTelephony.framework/CoreTelephony", RTLD_NOW)
        let CTGetSignalStrength2 = dlsym(libHandle, "CTGetSignalStrength")
        
        typealias CFunction = @convention(c) () -> Int
        
        if (CTGetSignalStrength2 != nil) {
            let fun = unsafeBitCast(CTGetSignalStrength2!, to: CFunction.self)
            let result = fun()
            return result
        }
        return nil
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
    enum InstagramErrors: String, LocalizedError {
        case InvalidToken = "Access token expired"
        
        var errorDescription: String? {
            return self.rawValue
        }
    }
    case InvalidURL(String)
    case Unknown
    case JSONError
}
