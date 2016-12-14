//
//  AdEvent.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import AdSupport

func generateUserData() -> [String:Any] {
    var userData : [String:Any] = [:]

    if(ASIdentifierManager.shared().isAdvertisingTrackingEnabled) {
        (ASIdentifierManager.shared().advertisingIdentifier.uuidString, "idfa") --> userData
    }

    KwizzadSDK.instance.model.userData.toDict(&userData);

    ("iOS", "PlatformType") --> userData
    ("0.7.5", "sdkVersion") --> userData
    // (osVersion, "OSVersion") --> userData
    ("1.0", "apiVersion") --> userData
    
    print("User data", userData);
    
    return userData;
}

open class AdEvent : KwizzadEvent {

    open let placementId: String?
    open let adId: String?

    open override func toDict(_ map: inout [String : Any]) {
        super.toDict(&map)
        (placementId, "placementId") --> map
        (adId, "adId") --> map
    }

    init(type: String, placementId: String?, adId: String?) {
        self.placementId = placementId
        self.adId = adId
        super.init(type: type)
    }

    init(type: String, placementId: String?) {
        self.placementId = placementId
        self.adId = nil
        super.init(type: type)
    }

    init(type: String, adId: String?) {
        self.placementId = nil
        self.adId = adId
        super.init(type: type)
    }

    override init(_ map: [String : Any]) {
        placementId = map["placementId"] as? String
        adId = map["adId"] as? String
        super.init(map)
    }
}
