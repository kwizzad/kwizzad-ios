//
//  Response.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

open class DeprecatedResponse : AdEvent, FromDict {
    public override required init(_ map: [String : Any]) {
        super.init(map)
    }
}

open class AdResponseEvent : AdEvent, FromDict {
    
    open let adType: String?
    open let expiry: Date?
    open var url: String?
    open let goalUrlPattern: String?
    open let closeButtonVisibility: String?
    open let rewards:[Reward]?
    
    public override required init(_ map: [String : Any]) {
        adType = map["adType"] as? String
        url = map["url"] as? String
        goalUrlPattern = map["goalUrlPattern"] as? String
        closeButtonVisibility = map["closeButtonVisibility"] as? String
        
        rewards = dictConvertToObject(arr: map["rewards"] as? [[String:Any]], type: Reward.self)
        
        expiry = fromISO8601(map["expiry"])
        
        super.init(map)
        
        kwlog.debug("will expire \(self.expiry)")
    }
}
