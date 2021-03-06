//
//  YouTubeResourceTypes.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 23/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit

struct YouTubeVideosResponse: Decodable {
    var videos:[YouTubeVideo]
    let nextPageToken:String
    private enum CodingKeys: String, CodingKey {
        case videos = "items", nextPageToken
    }
}

struct YouTubeVideo: Decodable {
    let id:String
    let channelId:String
    let title:String
    let channelTitle:String
    var thumbnailUrlString:String {
        return "https://i.ytimg.com/vi/\(id)/mqdefault.jpg"
    }
    var thumbnail: UIImage?
    var watchURL: URL? {
        return URL(string: "\(YouTubeAPI.shared.videoBaseURL)\(id)")
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, snippet
    }
    private enum SnippetKeys: String, CodingKey {
        case channelId, title, channelTitle
    }
    private enum IdKeys: String, CodingKey {
        case videoId
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let snippetContainer = try container.nestedContainer(keyedBy: SnippetKeys.self, forKey: .snippet)
        let idContainer = try container.nestedContainer(keyedBy: IdKeys.self, forKey: .id)
        self.id = try idContainer.decode(String.self, forKey: .videoId)
        self.channelId = try snippetContainer.decode(String.self, forKey: .channelId)
        self.title = try snippetContainer.decode(String.self, forKey: .title)
        self.channelTitle = try snippetContainer.decode(String.self, forKey: .channelTitle)
    }
}

enum YouTubeError:Error {
    case invalidURL(String)
    case networking(Error)
    case json(Error)
    case jsonFormat(String)
}
