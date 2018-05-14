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
import UserNotifications
import Reachability

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    var appIsStarting = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        //Perform Realm migration if needed
        let newSchemaVersion: UInt64 = 6
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
        
        // Set up push notifications
        if !UIApplication.shared.isRegisteredForRemoteNotifications {
            registerForPushNotifications()
        }
        
        // To enable sharing the userID between the app and its extensions, need to use AppGroups --> cannot use UserDefaults.standard anymore, handle migrating the data between the UserDefaults suits
        let userIDKey = "CacheServerUserID"
        let sharedUserDefaults = UserDefaults(suiteName: "group.com.DavidPasztor.ProactiveCacher")
        print("Shared UserDefaults: \(sharedUserDefaults ??? "No shared UserDefaults")")
        if sharedUserDefaults?.string(forKey: userIDKey) == nil {
            sharedUserDefaults?.set(UserDefaults.standard.string(forKey: userIDKey), forKey: userIDKey)
        }
        
        //TODO: before creating a new AppUsageLog, should check that the app wasn't opened by the system in response to a push notification but rather the user actually opened it (even though no video can be watched in the background, so we don't really care about extra AppUsageLogs with 0 watchedVideosCount --> no need to cache if the user opens the app but doesn't watch any videos)
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
                    try! realm.write {
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
        
        // Check if app was launched due to push notification
        if launchOptions?[.remoteNotification] != nil {
            appIsStarting = true
            //TODO: might have to move the notification handling to separate function that are called from here as well, since didReceiveNotifications might not be called if the app is opened due to the push notification (not sure though in the case of silent ones)
        }
        
        return true
    }
    
    // MARK: Push notifications
    func registerForPushNotifications() {
        // TODO: improve this function
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            //print("Permission granted: \(granted)")
            guard granted else { return }
            //TODO: else display an alert requesting the user to change the notification settings in Settings
            UNUserNotificationCenter.current().getNotificationSettings { (settings) in
                //print("Notification settings: \(settings)")
                guard settings.authorizationStatus == .authorized else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map({ return String(format: "%02.2hhx", $0)}).joined()
        print("Device Token: \(token)")
        CacheServerAPI.shared.userID = token
        print("UserID: \(CacheServerAPI.shared.userID!)")
        CacheServerAPI.shared.registerUser(completion: { result in
            switch result {
            case .success(_):
                print("Registration successful with userID: \(CacheServerAPI.shared.userID!)")
                let rootVC = UIApplication.shared.keyWindow?.rootViewController
                if let loadingVC = rootVC as? LoadingViewController {
                    loadingVC.displayVideos()
                } else if let navigationVC = rootVC as? UINavigationController, let loadingVC = navigationVC.topViewController as? LoadingViewController {
                    loadingVC.displayVideos()
                } else {
                    print("RootViewController is not LoadingViewController!")
                    print("RootVC: \(String(describing: UIApplication.shared.keyWindow?.rootViewController))")
                }
            case let .failure(error):
                if case let CacheServerErrors.HTTPFailureResponse(statusCode, _) = error, statusCode == 401 {
                    print("Error 401 when registering user")
                } else {
                    print("Error registering user: ",error)
                }
            }
        })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
        let alert = UIAlertController(title: "Couldn't set up push notifications", message: "Push notifications are essential for the use of this application. You might not have internet connection at the moment, please try again setting up the application once you are connected to the internet.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close app", style: .destructive, handler: { action in fatalError("Failed to registed for remote notifications: \(error)")}))
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let appState = application.applicationState
        print("Remote notification received with userInfo: \(userInfo)")
        if appState == .background || (appState == .inactive && !appIsStarting) {
            // Create UserLog
            if userInfo["message"] as? String == "Network Available" {
                UserDataLogger.shared.saveUserLogWithoutLocation()
                completionHandler(.noData)
            } else if let videoID = userInfo["videoID"] as? String {   // Download pushed video
                print("Caching video with ID \(videoID)")
                // Only cache the video if the device has wifi connection, don't do it on mobile network
                // If there's only mobile network, create a UserLog object instead
                if UserDataLogger.shared.reachability?.connection == .wifi {
                    CacheServerAPI.shared.cacheVideo(videoID, completion: { thumbnailResult, videoResult  in
                        switch (thumbnailResult,videoResult) {
                        case (.success(_),.success(_)):
                            print("Video and thumbnail cached successfully")
                            completionHandler(.newData)
                        case let (.failure(error),.success(_)):
                            print("Video cached, but failed to cache thumbnail: \(error)")
                            completionHandler(.newData)
                        case let (.success(_),.failure(error)):
                            print("Thumbnail cached, but error caching video: \(error)")
                            completionHandler(.failed)
                        case let (.failure(thumbnailError),.failure(videoError)):
                            print("Error caching video: \(videoError), erro caching thumbnail: \(thumbnailError)")
                            completionHandler(.failed)
                        }
                    })
                } else {
                    // No wifi available, so don't cache the video, but create a UserLog
                    print("Not caching content due to lack of wifi connection")
                    UserDataLogger.shared.saveUserLogWithoutLocation()
                }
            } else {
                print("Unrecognized notification payload: \(userInfo)")
                completionHandler(.noData)
            }
        } else if appState == .inactive && appIsStarting {
            //User touched notification
            completionHandler(.newData)
        } else {
            //App was already active
            completionHandler(.noData)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        appIsStarting = false
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        appIsStarting = false
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        appIsStarting = true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        appIsStarting = false
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

