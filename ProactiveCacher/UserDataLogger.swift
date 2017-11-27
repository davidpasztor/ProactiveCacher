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
    
    func saveBatteryState(){
        UIDevice.current.isBatteryMonitoringEnabled = true
        let batteryLog = BatteryStateLog()
        batteryLog.batteryPercentage = UIDevice.current.batteryLevel
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
        let realm = try! Realm()
        try! realm.write {
            realm.add(batteryLog)
        }
    }
    
    //Return download speed in kilobytes/sec
    func getDownloadSpeed()->Promise<Double>{
        return Promise{ fulfill, reject in
            let url = URL(string: "https://placehold.it/150/92c952")!
            let startDate = Date()
            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                guard data != nil, error != nil, let response = response else {
                    reject(error ?? AppErrors.DownloadSpeed.Generic); return
                }
                let expectedContentSize = response.expectedContentLength //content size in bytes
                guard expectedContentSize > 0 else {
                    reject(AppErrors.DownloadSpeed.NoHeader); return
                }
                let responseTime = -startDate.timeIntervalSinceNow //download time in seconds
                fulfill(Double(expectedContentSize/1000)/responseTime)
            }).resume()
        }
    }
    
    /*
    func locationUsageAuthorized()->Promise<Bool>{
        return Promise{ fulfill,reject in
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined:
                    CLLocationManager.requestAuthorization(type: .automatic).then{ authStatus->Void in
                        switch authStatus {
                            case .authorizedAlways, .authorizedWhenInUse:
                                fulfill(true)
                            default:
                                fulfill(false)
                        }
                    }.catch{ error in
                        reject(error)
                    }
                case .authorizedAlways, .authorizedWhenInUse:
                    fulfill(true)
                default:
                    fulfill(false)
            }
        }
    }
    */
}

enum AppErrors: Error {
    enum DownloadSpeed: String, LocalizedError {
        case NoHeader = "No content-length header in response"
        case Generic = "Can't measure download speed"
        
        var errorDescription: String? {
            return self.rawValue
        }
    }
}
