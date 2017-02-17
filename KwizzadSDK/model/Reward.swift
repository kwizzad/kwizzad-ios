//
//  Reward.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation


@objc(KwizzadReward)
open class Reward : NSObject, FromDict {
    // This is the actual amount of the reward.
    public let amount : NSNumber?
    // if this is defined, this is the maximal amount of the reward, so the actual reward can be lower than this.
    public let maxAmount : NSNumber?
    public let currency : String?
    // Defines which state you have to get to as user to actually get the reward.
    public let type : String?

    public func asFormattedString() -> String? {
        if let maxAmount = self.maxAmount, let currency = self.currency {
            return "up to \(maxAmount) \(currency)"
        }
        if let amount = self.amount, let currency = self.currency {
            return "\(amount) \(currency)"
        }
        return nil;
    }
    
    public func asDebugString() -> String? {
        if let maxAmount = self.maxAmount, let currency = self.currency {
            return "up to \(maxAmount) \(currency) for \(type)"
        }
        if let amount = self.amount, let currency = self.currency {
            return "\(amount) \(currency) for \(type)"
        }
        return nil;
    }
    
    public required init(_ map: [String : Any]) {
        amount = map["amount"] as? NSNumber
        maxAmount = map["maxAmount"] as? NSNumber
        currency = map["currency"] as? String
        
        if let rt = map["type"] as? String? {
            if let type = rt {
                self.type = type
            }
            else {
                type = "UNKNOWN"
            }
        }
        else {
            type = "UNKNOWN"
        }
        
    }
}
