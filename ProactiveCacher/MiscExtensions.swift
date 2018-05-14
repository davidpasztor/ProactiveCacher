//
//  MiscExtensions.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 14/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import Foundation

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
