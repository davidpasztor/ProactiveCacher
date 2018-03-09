//
//  CacheServerAPI.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 03/03/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import Foundation

class CacheServerAPI {
    //Create singleton instance
    static let shared = CacheServerAPI()
    private init(){}
    
    let baseURL = "http://35.153.159.19:3000" //"http://localhost:3000"
    
    var userID:String? {
        get {
            return UserDefaults.standard.string(forKey: "CacheServerUserID")
        }
        set(newValue){
            UserDefaults.standard.set(newValue, forKey: "CacheServerUserID")
        }
    }
    
    var headers:[String:String] {
        userID = userID ?? UUID().uuidString
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
        userID = UUID().uuidString
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
            guard response.statusCode == 206 else {
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
     - parameter completion: completion handler returning `Result.success(Data)` containing the thumbnail image data in case of success and `Result.failure(Error)` containing the error in case of failure. The completion closure is called on the main thread, so it is safe to do UI updates from inside the closure in other functions.
    */
    func getThumbnail(for video:String, completion: @escaping (Result<Data>)->()){
        let getThumbnailUrlString = "\(baseURL)/thumbnail?videoID=\(video)"
        guard let getThumbnailUrl = URL(string: getThumbnailUrlString) else {
            DispatchQueue.main.async {
                completion(Result.failure(CacheServerErrors.IncorrectURL(getThumbnailUrlString)))
            }
            return
        }
        URLSession.shared.dataTask(with: requestWithHeaders(for: getThumbnailUrl), completionHandler: { data, response, error in
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
        uploadVideoRequest.setValue("user", forHTTPHeaderField: headers["user"]!)
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
                completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response"))); return
            }
            guard response.statusCode == 200 || response.statusCode == 201 else {
                let errorResponse = String(data: data ?? Data(), encoding: .utf8)
                completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,errorResponse))); return
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
                    completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response"))); return
                }
                guard response.statusCode == 200 || response.statusCode == 201 else {
                    let errorResponse = String(data: data ?? Data(), encoding: .utf8)
                    completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,errorResponse))); return
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
