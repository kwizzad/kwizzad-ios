//
//  Response.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

let estimatedTimeForPlayingACampaign = 20.0 // in seconds

open class DeprecatedResponse : AdEvent, FromDict {
    public override required init(_ map: [String : Any]) {
        super.init(map)
    }
}

/// Holds metadata about an available ad, for example potential rewards and information about the campaign behind the ad.
@objc(KwizzadAdResponseEvent)
open class AdResponseEvent : AdEvent, FromDict {
    public let adType: String?
    
    /// At this date, the ad will expire and the client has to request a new one or the SDK will do it if automaticPreloading is set to true.
    public let expiry: Date?
    
    /// The expiry time in milliseconds until client has to request a new one or the SDK will do it if automaticPreloading is set to true.
    public var expiryInMilliseconds: Double?
    
    open func adWillExpireSoon() -> Bool {
        guard let  expiry = expiryInMilliseconds else { return false }
        return expiry < 5000;
    }
    
    /// An array of potential rewards.
    public let rewards:[Reward]?
    
    /// AdMetainfo object containing informations about the campaign.
    public let adMetaInfo: AdMetaInfo
    
    /// Holds campaign images like thumbnails, banners etc.
    public let images: [ImageInfo]?
    
    open var url: String?
    public let goalUrlPattern: String?
    public let kometArchiveUrl: String?
    public let closeButtonVisibility: String?

    var expiryTimer : Foundation.Timer?

    public override required init(_ map: [String : Any]) {
        adType = map["adType"] as? String
        url = map["url"] as? String
        goalUrlPattern = map["goalUrlPattern"] as? String
        kometArchiveUrl = map["kometArchiveUrl"] as? String
        closeButtonVisibility = map["closeButtonVisibility"] as? String
        
        rewards = dictConvertToObject(arr: map["rewards"] as? [[String:Any]], type: Reward.self)
        
        expiry = fromISO8601(map["expiry"])
        expiryInMilliseconds = map["expiresIn"] as? Double
    
        adMetaInfo = AdMetaInfo(map["ad"] as? [String:Any] ?? [:])
        images = dictConvertToObject(arr: map["images"] as? [[String:Any]], type: ImageInfo.self)

        super.init(map)
        
        logger.logMessage("will expire \(String(describing: self.expiry))")
        
        if (KwizzadSDK.instance.preloadAdsAutomatically) {
            self.updateExpiryTime()
        }
    }
    
    /// Helper function for getting a squared thumbnail image url.
    /// - Parameter width: the desired width of the thumbnail.
    /// - returns: The URL of the thumbnail image as a string.
    public func squaredThumbnailURL(width: Int = 200) -> String? {
        let imageInfo : ImageInfo? = images?.first(where: { $0.type == "header" } );
        return imageInfo?.url(width);
    }
    
    func updateExpiryTime () {
        if (expiryInMilliseconds != nil) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(expiryInMilliseconds!))) {
                self.expiryInMilliseconds = 0
            }
        }
    }
}
