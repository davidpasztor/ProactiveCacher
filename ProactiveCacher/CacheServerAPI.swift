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
    
    let baseURL = "http://localhost:3000"//"http://35.153.159.19:3000" //"http://localhost:3000"
    
    var userID:String? {
        get {
            return UserDefaults.standard.string(forKey: "CacheServerUserID")
        }
        set(newValue){
            print("Setting userID to \(newValue ?? "nil")")
            UserDefaults.standard.set(newValue, forKey: "CacheServerUserID")
        }
    }
    
    var headers:[String:String] {
        userID = userID ?? UUID().uuidString
        return ["user":userID!]
    }
    
    func requestWithHeaders(for url:URL, method: String = "GET")->URLRequest{
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method
        return request
    }
    
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
            guard response.statusCode == 200 || response.statusCode == 206 else {
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
                completion(Result.failure(error!)); return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response"))); return
            }
            guard response.statusCode == 200 else {
                let errorResponse = String(data: data ?? Data(), encoding: .utf8)
                completion(Result.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,errorResponse))); return
            }
            completion(Result.success(()))
        }).resume()
    }
    
    func streamVideo(with youtubeID:String, completion: @escaping (Result<String>)->()){
        let streamVideoUrlString = "\(baseURL)/startStream?videoID=\(youtubeID)"
        guard let streamVideoUrl = URL(string: streamVideoUrlString) else {
            DispatchQueue.main.async {
                completion(Result.failure(CacheServerErrors.IncorrectURL(streamVideoUrlString)))
            }
            return
        }
        URLSession.shared.dataTask(with: requestWithHeaders(for: streamVideoUrl), completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(Result.failure(error!))
                }
                return
            }
            guard let htmlString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    completion(Result.failure(CacheServerErrors.CustomMessage("Couldn't convert stream response to HTML String")))
                }
                return
            }
            DispatchQueue.main.async {
                completion(Result.success(htmlString))
            }
        }).resume()
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
