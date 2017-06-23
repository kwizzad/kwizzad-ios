//
//  AdTrackingEvent.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 17.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

class AdTrackingEvent : AdEvent, ToDict {
    var customParameters : [Param]? = nil;
    var step : Int?
    
    class Param : ToDict {
        
        var key: String?
        var value: Any?
        
        public init(_ key: String, _ value: Any) {
            self.key = key
            self.value = value
        }
        
        func toDict(_ map: inout [String : Any]) {
            (key, "key") --> map
            (value, "value") --> map
        }
    }
    
    public init(action type: String, forAd adId: String) {
        super.init(type: type, adId: adId)
    }
    
    open func setStep(_ step:Int) -> AdTrackingEvent {
        self.step = step;
        return self
    }
    
    open func customParam(_ key: String, value: Any) -> AdTrackingEvent {
        if customParameters == nil {
            customParameters = []
        }
        customParameters!.append(Param(key,value))
        return self
    }
    
    open func customParams(_ params : [String:Any]?) -> AdTrackingEvent {
        if params != nil && params!.count > 0 {
            if customParameters == nil {
                customParameters = []
            }
            
            for (key,val) in params! {
                customParameters!.append(Param(key,val))
            }
        }
        return self
    }
    
    
    open override func toDict(_ map: inout [String : Any]) {
        super.toDict(&map)
        (customParameters, "customParameters") --> map
        (step, "step") --> map
    }
}
