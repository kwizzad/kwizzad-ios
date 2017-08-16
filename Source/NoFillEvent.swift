//
//  NoFillEvent.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

open class NoFillEvent : AdEvent, FromDict {
    
    open let retryAfter: Date?
    public var retryInMilliseconds: Double?

    public override required init(_ map: [String : Any]) {
        retryAfter = fromISO8601(map["retryAfter"])
        retryInMilliseconds = map["retryIn"] as? Double
        super.init(map)
        
        if (KwizzadSDK.instance.preloadAdsAutomatically) {
            self.updateExpiryTime()
        }
    }
    
    func updateExpiryTime () {
        if (retryInMilliseconds != nil) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(retryInMilliseconds!))) {
                self.retryInMilliseconds = 0
            }
        }
    }
}
