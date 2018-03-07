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
    
    func getVideoList(completion: @escaping (Result<[Video]>)->()){
        let videosUrl = URL(string: "\(baseURL)/videos")!
        URLSession.shared.dataTask(with: videosUrl, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    completion(Result.failure(error!))
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
        URLSession.shared.dataTask(with: getThumbnailUrl, completionHandler: { data, response, error in
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
        print(String(data:uploadVideoRequest.httpBody ?? Data(),encoding: .utf8) ?? "JSON Encoding of URL failed")
        URLSession.shared.dataTask(with: uploadVideoRequest, completionHandler: { data, response, error in
            guard error == nil else {
                completion(Result.failure(error!)); return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(Result.failure(CacheServerErrors.CustomMessage("No HTTP response"))); return
            }
            guard response.statusCode == 200 else {
                let errorResponse:String? = String(data: data ?? Data(), encoding: .utf8)
                /*
                if let data = data {
                    errorResponse = (try? JSONSerialization.jsonObject(with: data)) as? String
                } else {
                    errorResponse = nil
                }
                */
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
        URLSession.shared.dataTask(with: streamVideoUrl, completionHandler: { data, response, error in
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
