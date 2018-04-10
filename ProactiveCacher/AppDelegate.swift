//
//  AppDelegate.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/11/2017.
//  Copyright © 2017 Pásztor Dávid. All rights reserved.
//

import UIKit
import RealmSwift
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //Perform Realm migration if needed
        let newSchemaVersion: UInt64 = 5
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: newSchemaVersion,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 3 && newSchemaVersion == 3) {
                    // Need to migrate UserLog objects
                    migration.enumerateObjects(ofType: UserLog.className(), { oldObject, newObject in
                        let oldLocation = oldObject!["location"] as! MigrationObject
                        let timeStamp = oldLocation["timeStamp"] as! Date
                        newObject!["_timeStampString"] = ISO8601DateFormatter().string(from: timeStamp)
                    })
                } else if (oldSchemaVersion < newSchemaVersion) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        let _ = try! Realm()
        debugPrint("Realm location: \(Realm.Configuration.defaultConfiguration.fileURL!)")
        
        // Save the opening time of the app for future caching decisions
        let appAccessLog = UserDataLogger.shared.createAppAccessLog()
        switch appAccessLog {
        case let .failure(error):
            print("Error creating app access log : \(error)")
        case .success(_):
            print("App access log successfully created")
        }
        
        //Upload the previous app usage logs to the backend
        let previousAppUsageLogs = AppUsageLog.previous
        print("There are \(previousAppUsageLogs.count) app usage logs to upload")
        if previousAppUsageLogs.count > 0 {
            CacheServerAPI.shared.uploadAppUsageLogs(Array(previousAppUsageLogs), completion: { result in
                switch result {
                case .success(_):
                    let realm = try! Realm()
                    try! Realm().write {
                        realm.delete(previousAppUsageLogs)
                    }
                    print("App usage logs uploaded successfully and deleted from Realm")
                case let .failure(error):
                    print("App usage logs upload failed with \(error)")
                }
            })
        }
        
        do {
            // Videos have sound even if the phone in silent mode
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Can't set up AVAudioSession properties, ",error)
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

