//
//  UserDataModel.swift
//  KwizzadSDK
//
//  Created by Sebastian on 23/11/2016.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation


@objc(KwizzadGender)
public enum Gender : Int, CustomStringConvertible {
    case Male
    case Female
    case Unknown
    
    public var description: String {
        get {
            switch self {
            case .Female: return "FEMALE"
            case .Male: return "MALE"
            default: return "UNKNOWN"
            }
        }
    }
}


@objc(KwizzadUserDataModel)
open class UserDataModel : NSObject, ToDict {
        public var gender: Gender = Gender.Unknown
        public var userName: String?
        public var userId: String?
        public var facebookUserId: String?
        
        public func toDict(_ map: inout [String : Any]) {
            (gender.description, "gender") --> map
            (userName, "userName") --> map
            (userId, "userId") --> map
            (facebookUserId, "facebookUserId") --> map
        }
}
