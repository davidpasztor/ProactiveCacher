//
//  MiscExtensions.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 14/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit

infix operator ???

extension Optional {
    /**
     Operator for String interpolation of Optional values. Returns the interpolated value of type Wrapped in case the Optional is holding a value, if the Optional is `nil`, it returns `errorString`.
     - parameter wrappedValue: wrapped optional value to String interpolate
     - parameter errorString: `String` value to use as the default value in case `wrappedValue` is `nil`
     */
    static func ???(wrappedValue:Optional<Wrapped>, errorString:String)->String{
        switch wrappedValue {
        case .none:
            return errorString
        case let .some(value):
            return "\(value)"
        }
    }
}

/*
// Function that dispatches any closure from its input to the main thread. Can be used for calling completion handlers from async methods to ensure that any code executed in the completion handler of those methods can safely update the UI, since the completion handler was already dispatched to the main queue.
func dispatchToMain<Input,Return>(closure:(Input)->(Return)){
    DispatchQueue.main.async {
        closure()
    }
}
*/

extension UIImage {
    /**
     Download an image from a remote URL asynchronously.
     - parameter url: remote URL pointing to the image file itself
     - parameter completion: completion handler returning the `UIImage` wrapped in a `Result`
     */
    static func downloadFromRemoteURL(_ url: URL, completion: @escaping (Result<UIImage>)->()) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async{
                    completion(.failure(error!))
                }
                return
            }
            DispatchQueue.main.async() {
                completion(.success(image))
            }
        }.resume()
    }
}
