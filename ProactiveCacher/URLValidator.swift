//
//  UrlValidator.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 14/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import Foundation

class URLValidator {
    private static let youtubeIDRegex = try! NSRegularExpression(pattern: "\\?v=-?(\\w+)")
    private static let possibleYoutubeHosts = ["www.youtube.com","youtube.com","youtu.be"]
    
    /**
     Assess if a supplied String is a valid URL pointing to a YouTube video or not.
     */
    static func validateYouTubeURL(urlString:String)->Bool{
        guard let youtubeUrl = URL(string: urlString) else {return false}
        guard let host = youtubeUrl.host, possibleYoutubeHosts.contains(host) else {return false}
        guard youtubeIDRegex.matches(in: urlString).count == 1 else {return false}
        return true
    }
    
    /**
     Get the video ID from a YouTube URL. Return `nil` if the URL doesn't point to a YouTube video.
     */
    static func extractYouTubeID(from urlString:String)->String?{
        return youtubeIDRegex.firstCapturedString(in: urlString)
    }
}

extension NSRegularExpression {
    /**
     Returns an array containing all matches of the regular expression in the full string.
     */
    func matches(in string: String)->[NSTextCheckingResult]{
        return matches(in: string, range: NSRange(location: 0, length: (string as NSString).length))
    }
    
    /**
     Returns an array containing all matched substrings of the regular expression in the full string.
     */
    func matchedStrings(in string: String)->[String]{
        let nsString = string as NSString
        return matches(in: string).map{nsString.substring(with: $0.range)}
    }
    
    func firstMatch(in string:String)->NSTextCheckingResult?{
        return firstMatch(in: string, range: NSRange(location: 0, length: (string as NSString).length))
    }
    
    func firstMatchedString(in string:String)->String?{
        guard let match = firstMatch(in: string) else {return nil}
        return (string as NSString).substring(with: match.range)
    }
    
    /**
     Returns the substring in the first capture group matched by the regular expression in the full string.
     */
    func firstCapturedString(in string:String)->String?{
        guard numberOfCaptureGroups == 1 else {return nil}
        guard let capturedRange = firstMatch(in: string)?.range(at: 1) else {return nil}
        return (string as NSString).substring(with: capturedRange)
    }
}
