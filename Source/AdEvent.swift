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
    let version = Bundle(for: KwizzadSDK.self).infoDictionary?["CFBundleShortVersionString"];
    let device = UIDevice.current
    var systemInfo = utsname()
    uname(&systemInfo)
    let modelCode = withUnsafePointer(to: &systemInfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            ptr in String.init(validatingUTF8: ptr)
            
        }
    }

    
    ("1.0", "apiVersion") --> userData
    ("iOS", "PlatformType") --> userData
    (version, "sdkVersion") --> userData
    (device.systemVersion, "OSVersion") --> userData
    (device.model + "|" + (modelCode ?? "unknown"), "deviceInformation") --> userData
    let screenRect = UIScreen.main.bounds;
    let screenWidth = screenRect.size.width;
    let screenHeight = screenRect.size.height;
    (screenWidth, "screenWidth") --> userData;
    (screenHeight, "screenHeight") --> userData;
    (UIScreen.main.nativeScale, "devicePixelRatio") --> userData;
    
    let bundleApp = Bundle.main;
    let bundleDisplayName = bundleApp.object(forInfoDictionaryKey: "CFBundleName") as? String;
    (bundleDisplayName, "userAgent") --> userData;
    let bundleIdentifier = bundleApp.bundleIdentifier
    let bundleVersion = bundleApp.infoDictionary?["CFBundleShortVersionString"];
    (bundleIdentifier, "packageName") --> userData
    (bundleVersion, "appVersion") --> userData
    
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
