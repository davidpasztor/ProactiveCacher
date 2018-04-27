//
//  CacheServerAPI.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 03/03/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import Foundation
import RealmSwift

class CacheServerAPI {
    //Create singleton instance
    static let shared = CacheServerAPI()
    private init(){}
    
    //let baseURL = "http://192.168.1.95:3000" // Can only be used for local testing from a real device
    //let baseURL = "http://localhost:3000" // Can only be used for local testing in the Simulator
    let baseURL = "http://35.153.159.19:3000" // AWS server IP address
    
    var userID:String? {
        get {
            return UserDefaults.standard.string(forKey: "CacheServerUserID")
        }
        set(newValue){
            UserDefaults.standard.set(newValue, forKey: "CacheServerUserID")
        }
    }
    
    private var headers:[String:String] {
        #if targetEnvironment(simulator)
            userID = userID ?? "iOS Simulator"
        #endif
        return ["user":userID!]
    }
    
    /**
     Create a URLRequest object from a URL containing all necessary headers for the CacheServer REST API
     - parameter url: URL representing the API endpoint to call
     - parameter method: HTTP verb, defaults to GET
     - parameter body: httpBody to include in the request, defaults to nil, only used for POST requests
     - returns: URLRequest with the specified URL, authorization headers and httpBody for POST request
    */
    func requestWithHeaders(for url:URL, method: String = "GET", body: Data? = nil)->URLRequest{
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method
        if method == "POST" {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }
    
    /**
     Register user to the CacheServer API by calling the register endpoint. The userID is generated at random. Only call this method if there's no registered user for this app or if the server responds with HTTP status code 401 for the existing userID.
     - parameter completion: completion handler returning `Result.success(Void)` in case of success and `Result.failure(Error)` containing the error in case of failure
    */
    func registerUser(completion: @escaping (Result<()>)->()){
        var registerUrlRequest = URLRequest(url: URL(string: "\(baseURL)/register")!)
        registerUrlRequest.httpMethod = "POST"
        registerUrlRequest.httpBody = try? JSONEncoder().encode(["userID":userID!])
        registerUrlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: registerUrlRequest, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(Result.failure(error!))
                }
                return
            }
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response")))
                }
                return
            }
            guard response.statusCode == 201 else {
                let failureResponse = (try? JSONDecoder().decode([String:String].self, from: data))?["error"]
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,failureResponse)))
                }
                return
            }
            DispatchQueue.main.async {
                completion(Result.success(()))
            }
        }).resume()
    }
    
    /**
     Retrieve all available videos from the server.
     - parameter completion: completion handler returning `Result.success([Videos])` in case of success and `Result.failure(Error)` containing the error in case of failure
     */
    func getVideoList(completion: @escaping (Result<[Video]>)->()){
        let videosUrl = URL(string: "\(baseURL)/videos")!
        URLSession.shared.dataTask(with: requestWithHeaders(for: videosUrl), completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(Result.failure(error!))
                }
                return
            }
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response")))
                }
                return
            }
            guard response.statusCode == 200 || response.statusCode == 201 else {
                if response.statusCode == 401 {
                    self.userID = nil
                }
                let failureResponse = (try? JSONDecoder().decode([String:String].self, from: data))?["error"]
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode, failureResponse)))
                }
                return
            }
            do {
                let videos = try JSONDecoder().decode([Video].self, from: data)
                DispatchQueue.main.async {
                    completion(Result.success(videos))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(Result.failure(error))
                }
            }
        }).resume()
    }
    
    /**
     Download the thumbnail image for a given video from the API.
     - parameter video: YouTube ID of the video for which the thumbnail is requested
     - parameter urlSession: `URLSession` object to use for the `dataTask`. Can be used to allow execution in the background using a background `URLSessionConfiguration`.
     - parameter completion: completion handler returning `Result.success(Data)` containing the thumbnail image data in case of success and `Result.failure(Error)` containing the error in case of failure. The completion closure is called on the main thread, so it is safe to do UI updates from inside the closure in other functions.
    */
    func getThumbnail(for video:String,using urlSession:URLSession=URLSession.shared, completion: @escaping (Result<Data>)->()){
        let getThumbnailUrlString = "\(baseURL)/thumbnail?videoID=\(video)"
        guard let getThumbnailUrl = URL(string: getThumbnailUrlString) else {
            DispatchQueue.main.async {
                completion(Result.failure(CacheServerErrors.IncorrectURL(getThumbnailUrlString)))
            }
            return
        }
        urlSession.dataTask(with: requestWithHeaders(for: getThumbnailUrl), completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(Result.failure(error!))
                }
                return
            }
            DispatchQueue.main.async {
                completion(Result.success(data))
            }
        }).resume()
    }
    
    /**
     Upload a YouTube video directly from YouTube to the server.
     - parameter youtubeUrl: YouTube URL of the video to be uploaded. Must be a valid URL pointing to a YouTube video.
     - parameter completion: completion handler returning `Result.success(Void)` in case of success and `Result.failure(Error)` containing the error in case of failure
     */
    func uploadVideo(with youtubeUrl:URL,completion: @escaping (Result<Void>)->()){
        let uploadVideoUrl = URL(string: "\(baseURL)/storage")!
        var uploadVideoRequest = URLRequest(url: uploadVideoUrl)
        uploadVideoRequest.httpMethod = "POST"
        //uploadVideoRequest.httpBody = try? JSONEncoder().encode(["url":youtubeUrl])
        uploadVideoRequest.httpBody = try? JSONSerialization.data(withJSONObject: ["url":youtubeUrl.absoluteString])
        uploadVideoRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
        uploadVideoRequest.setValue(headers["user"]!, forHTTPHeaderField: "user")
        URLSession.shared.dataTask(with: uploadVideoRequest, completionHandler: { data, response, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(Result.failure(error!))
                }
                return
            }
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response")))
                }
                return
            }
            guard response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202 else {
                let errorResponse = String(data: data ?? Data(), encoding: .utf8)
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,errorResponse)))
                }
                return
            }
            DispatchQueue.main.async {
                completion(Result.success(()))
            }
        }).resume()
    }
    
    /**
     Upload a rating from the user for a specific video.
     - parameter youtubeID: YouTube ID of the video the user just rated
     - parameter completion: completion handler returning `Result.success(Void)` in case of success and `Result.failure(Error)` containing the error in case of failure
     */
    func rateVideo(with youtubeID:String, rating:Double, completion: @escaping (Result<()>)->()){
        let rateVideoUrl = URL(string: "\(baseURL)/videos/rate")!
        let requestBody = try? JSONSerialization.data(withJSONObject: ["videoID":youtubeID,"rating":rating])
        URLSession.shared.dataTask(with: requestWithHeaders(for: rateVideoUrl, method: "POST",body: requestBody), completionHandler: { data, response, error in
            guard error == nil else {
                DispatchQueue.main.async {
                    completion(Result.failure(error!))
                }
                return
            }
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response")))
                }
                return
            }
            guard response.statusCode == 200 || response.statusCode == 201 else {
                let errorResponse = String(data: data ?? Data(), encoding: .utf8)
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,errorResponse)))
                }
                return
            }
            DispatchQueue.main.async {
                completion(Result.success(()))
            }
        }).resume()
    }
    
    /**
     Upload one or more UserLog objects to the server. The UserLogs are added to the User corresponding to the userID in the request header.
     - parameter logs: UserLogs to upload
     - parameter completion: completion handler returning `Result.success(Void)` in case of success and `Result.failure(Error)` containing the error in case of failure
     */
    func uploadUserLogs(_ logs:[UserLog], completion: @escaping (Result<()>)->()){
        let userLogsUrl = URL(string: "\(baseURL)/userlogs")!
        do {
            let requestBody = try JSONEncoder().encode(logs)
            let userLogsUploadRequest = requestWithHeaders(for: userLogsUrl, method: "POST", body: requestBody)
            URLSession.shared.dataTask(with: userLogsUploadRequest, completionHandler: { data, response, error in
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(Result.failure(error!))
                    }
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response")))
                    }
                    return
                }
                guard response.statusCode == 200 || response.statusCode == 201 else {
                    let errorResponse = String(data: data ?? Data(), encoding: .utf8)
                    DispatchQueue.main.async {
                        completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,errorResponse)))
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(Result.success(()))
                }
            }).resume()
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
    }
    
    func uploadUserLogs(_ logs:UserLog, completion: @escaping (Result<()>)->()){
        uploadUserLogs([logs], completion: completion)
    }
    
    /**
     Upload one or more AppUsageLog objects to the server. The AppUsageLog are added to the User corresponding to the userID in the request header.
     - parameter logs: AppUsageLogs to upload
     - parameter completion: completion handler returning `Result.success(Void)` in case of success and `Result.failure(Error)` containing the error in case of failure
     */
    func uploadAppUsageLogs(_ logs:[AppUsageLog], completion: @escaping (Result<()>)->()){
        let appLogsUrl = URL(string: "\(baseURL)/applogs")!
        do {
            let requestBody = try JSONEncoder().encode(logs)
            let appLogsUploadRequest = requestWithHeaders(for: appLogsUrl, method: "POST", body: requestBody)
            URLSession.shared.dataTask(with: appLogsUploadRequest, completionHandler: { data, response, error in
                guard error == nil else {
                    DispatchQueue.main.async {
                        completion(Result.failure(error!))
                    }
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    DispatchQueue.main.async {
                        completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response")))
                    }
                    return
                }
                guard response.statusCode == 200 || response.statusCode == 201 else {
                    let errorResponse = String(data: data ?? Data(), encoding: .utf8)
                    DispatchQueue.main.async {
                        completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,errorResponse)))
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(Result.success(()))
                }
            }).resume()
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            return
        }
    }
    
    /**
        Save a video along with its thumbnail on disk. The video file and its thumbnail image are saved to disk and the file locations are persisted to the corresponding `Video` object in Realm.
     - parameter videoID: ID of the video to be downloaded
     - parameter completion: completion handler returning `Result.success(Void)` in case of success and `Result.failure(Error)` containing the error in case of failure
     */
    func cacheVideo(_ videoID:String, completion: @escaping (_ thumbnailDownload:Result<()>,_ videoDownload:Result<()>)->()){
        // Check if a Video object already exists for the given ID or not
        var video:Video
        let realm = try! Realm()
        if let fetchedVideo = realm.object(ofType: Video.self, forPrimaryKey: videoID) {
            video = fetchedVideo
        } else {
            video = Video()
        }
        //let backgroundUrlSession = URLSession(configuration: URLSessionConfiguration.background(withIdentifier: "CacheSession"))
        let backgroundUrlSession = URLSession.shared
        let cacheDispatchGroup = DispatchGroup()
        var thumbnailResult:Result<()> = .failure(AppErrors.Unknown)
        var videoResult:Result<()> = .failure(AppErrors.Unknown)
        // Cache the video if it wasn't already cached
        if video.filePath == nil {
            let streamUrlString = "\(CacheServerAPI.shared.baseURL)/stream?videoID=\(video.youtubeID)&user=\(CacheServerAPI.shared.userID!)"
            guard let streamURL = URL(string: streamUrlString) else {
                videoResult = .failure(AppErrors.InvalidURL(streamUrlString))
                return
            }
            cacheDispatchGroup.enter()
            // Download the video
            //let videoThreadSafeReference = ThreadSafeReference(to: video)
            backgroundUrlSession.dataTask(with: streamURL, completionHandler: { data, response, error in
                guard let data = data, error == nil else {
                    videoResult = .failure(error!)
                    cacheDispatchGroup.leave()
                    return
                }
                do {
                    let videosDirectory = try FileManager.default.videosDirectory()
                    let relativeVideoPath = "\(videoID).mp4"
                    //Need to refetch video to avoid access from incorrect thread error
                    let realm = try! Realm()
                    let video = realm.object(ofType: Video.self, forPrimaryKey: videoID)
                    try data.write(to: videosDirectory.appendingPathComponent(relativeVideoPath))
                    try! realm.write {
                        video?.filePath = relativeVideoPath
                    }
                    videoResult = .success(())
                } catch {
                    videoResult = .failure(error)
                }
                cacheDispatchGroup.leave()
            }).resume()
        }
        // Cache the thumbnail if it wasn't already cached
        if video.thumbnailPath == nil {
            cacheDispatchGroup.enter()
            // Getting the thumbnail
            CacheServerAPI.shared.getThumbnail(for: videoID,using: backgroundUrlSession, completion: { result in
                if case let .success(thumbnailData) = result {
                    do {
                        let thumbnailsDirectory = try FileManager.default.thumbnailsDirectory()
                        let relativeThumbnailPath = "\(videoID).jpg"
                        //Need to refetch video to avoid access from incorrect thread error
                        let realm = try! Realm()
                        let video = realm.object(ofType: Video.self, forPrimaryKey: videoID)
                        try thumbnailData.write(to: thumbnailsDirectory.appendingPathComponent(relativeThumbnailPath))
                        try! realm.write {
                            video?.thumbnailPath = relativeThumbnailPath
                        }
                        thumbnailResult = .success(())
                    } catch {
                        thumbnailResult = .failure(error)
                    }
                } else if case let .failure(error) = result {
                    thumbnailResult = .failure(error)
                }
                cacheDispatchGroup.leave()
            })
        }
        cacheDispatchGroup.notify(queue: DispatchQueue.main, execute: {
            DispatchQueue.main.async {
                completion(thumbnailResult,videoResult)
            }
        })
    }
}

enum Result<T>{
    case success(T)
    case failure(Error)
}

enum CacheServerErrors: Error {
    case InvalidJSONResponse
    case GenericError(Error)
    case CustomMessage(String)
    case IncorrectURL(String)
    case HTTPFailureResponse(Int,String?)
}
