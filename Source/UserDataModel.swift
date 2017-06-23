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


/// UserDataModel: Holds end user data. You can use this to get better targeting for ads.
/// This also helps to ensure the same user does not see the same campaign multiple times.
@objc(KwizzadUserDataModel)
open class UserDataModel : NSObject, ToDict {
    /// The user's selected gender, if applicable.
    public var gender: Gender = Gender.Unknown
    
    /// The user's unique user name within your app.
    public var userName: String = ""
    
    /// A unique ID that identifies the user within your app.
    public var userId: String = ""
    
    /// The user's facebook user ID.
    public var facebookUserId: String = ""
    
    public func toDict(_ map: inout [String : Any]) {
        (gender.description, "gender") --> map
        (userName, "userName") --> map
        (userId, "userId") --> map
        (facebookUserId, "facebookUserId") --> map
    }
}
