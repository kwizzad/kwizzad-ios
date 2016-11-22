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
    
    public override required init(_ map: [String : Any]) {
        retryAfter = fromISO8601(map["retryAfter"])
        super.init(map)
    }
}
