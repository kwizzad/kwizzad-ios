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
    open let adType: String?
    
    /// At this date, the ad will expire and the client has to request a new one.
    public let expiry: Date?
    
    open func adWillExpireSoon() -> Bool {
        guard let expiry = expiry else { return false }
        return expiry.timeIntervalSinceNow - estimatedTimeForPlayingACampaign < 0;
    }
    
    /// An array of potential rewards.
    open let rewards:[Reward]?
    
    /// AdMetainfo object containing informations about the campaign.
    open let adMetaInfo: AdMetaInfo
    
    /// Holds campaign images like thumbnails, banners etc.
    open let images: [ImageInfo]?
    
    open var url: String?
    open let goalUrlPattern: String?
    open let closeButtonVisibility: String?

    public override required init(_ map: [String : Any]) {
        adType = map["adType"] as? String
        url = map["url"] as? String
        goalUrlPattern = map["goalUrlPattern"] as? String
        closeButtonVisibility = map["closeButtonVisibility"] as? String
        
        rewards = dictConvertToObject(arr: map["rewards"] as? [[String:Any]], type: Reward.self)
        
        expiry = fromISO8601(map["expiry"])
        
        adMetaInfo = AdMetaInfo(map["ad"] as? [String:Any] ?? [:])
        images = dictConvertToObject(arr: map["images"] as? [[String:Any]], type: ImageInfo.self)

        super.init(map)
        
        logger.logMessage("will expire \(String(describing: self.expiry))")
    }
    
    /// Helper function for getting a squared thumbnail image url.
    /// - Parameter width: the desired width of the thumbnail.
    /// - returns: The URL of the thumbnail image as a string.
    public func squaredThumbnailURL(width: Int = 200) -> String? {
        let imageInfo : ImageInfo? = images?.first(where: { $0.type == "header" } );
        return imageInfo?.url(width);
    }
}
