//
//  Request.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

open class KwizzadEvent {
    open let type:String?
    open var eventTimestamp:Date?
    
    init(type: String) {
        self.type = type
        self.eventTimestamp = Date()
    }
    
    init(_ map: [String : Any]) {
        type = map["type"] as? String
        eventTimestamp = fromISO8601(map["eventTimestamp"])
    }
    
    open func toDict(_ map: inout [String : Any]) {
        (type, "type") --> map
        (toISO8601(eventTimestamp), "eventTimestamp") --> map
    }
    
    
    
}
