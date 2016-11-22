//
//  AdRequestEvent.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import AdSupport

open class AdRequestEvent : AdEvent, ToDict {
    fileprivate var idfa : String?;
    
    public init(placementId: String) {
        if(ASIdentifierManager.shared().isAdvertisingTrackingEnabled) {
            idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString;
        }
        
        super.init(type: "adRequest", placementId: placementId)
    }
    
    open override func toDict(_ map: inout [String : Any]) {
        super.toDict(&map)
        (idfa, "idfa") --> map
        (generateUserData(), "userData") --> map
    }
}
