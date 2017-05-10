//
//  AdMetaInfo
//  KwizzadSDK
//
//  Created by Sebastian Felix Zappe on 06/04/2017.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import Foundation

/// This information describes a campaign that a user can play.
/// It can be used to be displayed on a clickable ad that opens Kwizzad.
@objc(KwizzadAdMetaInfo)
open class AdMetaInfo : NSObject, FromDict {
    /// Headline of the campaign.
    public var headline : String?
    /// Teaser of the campaign.
    public var teaser : String?
    /// Brand of the campaign.
    public var brand : String?

    public required init(_ map: [String : Any]) {
        if let headline = map["headline"] as? String {
            if (headline != "") {
                self.headline = headline;
            }
        }
        if let teaser = map["teaser"] as? String {
            if (teaser != "") {
                self.teaser = teaser;
            }
        }
        if let brand = map["brand"] as? String {
            if (brand != "") {
                self.brand = brand;
            }
        }
    }
}
