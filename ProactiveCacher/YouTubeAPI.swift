//
//  YouTubeAPI.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 23/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit

class YouTubeAPI {
    // Create a singleton instance
    static let shared = YouTubeAPI()
    private init(){}
    
    private let apiKey = "AIzaSyBHmIX8EfCwI1o77jUpjtM1gCP1wlQRPOk"
    let baseUrlString = "https://www.googleapis.com/youtube/v3"
    
    func searchVideos(keyword:String,in category:String?, completion: @escaping (Result<[YouTubeVideo]>)->()){
        let categoryParam = category == nil ? "" : "&videoCategoryId\(category!)"
        let searchQuery = "?q=\(keyword)&part=snippet&maxResults=20&type=video&key=\(apiKey)\(categoryParam)"
        guard let encodedSearchQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let searchUrl = URL(string: "\(baseUrlString)/search/\(encodedSearchQuery)") else {
            DispatchQueue.main.async {
                completion(.failure(AppErrors.InvalidURL("\(self.baseUrlString)/search\(searchQuery)")))
            }
            return
        }
        print(searchUrl.absoluteString)
        URLSession.shared.dataTask(with: searchUrl, completionHandler: { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error!))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(CacheServerErrors.CustomMessage("No HTTP response"))) }
                return
            }
            guard response.statusCode >= 200 && response.statusCode <= 300 else {
                let errorResponse = String(data: data, encoding: .utf8)
                DispatchQueue.main.async {
                    completion(.failure(CacheServerErrors.HTTPFailureResponse(response.statusCode,errorResponse)))
                }
                return
            }
            do {
                var matchingVideosResponse = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
                let thumbnailsGroup = DispatchGroup()
                for index in matchingVideosResponse.videos.indices {
                    guard let url = URL(string: matchingVideosResponse.videos[index].thumbnailResponse.url) else { continue }
                    thumbnailsGroup.enter()
                    UIImage.downloadFromRemoteURL(url, completion: { result in
                        switch result {
                        case let .failure(error):
                            print(error)
                        case let .success(image):
                            matchingVideosResponse.videos[index].thumbnail = image
                        }
                        thumbnailsGroup.leave()
                    })
                }
                thumbnailsGroup.notify(queue: DispatchQueue.main, execute: {
                    completion(.success(matchingVideosResponse.videos))
                })

                DispatchQueue.main.async {
                    completion(.success(matchingVideosResponse.videos))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }).resume()
    }
}
