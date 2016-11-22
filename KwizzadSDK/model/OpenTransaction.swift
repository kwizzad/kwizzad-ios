//
//  OpenTransaction.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

@objc(KwizzadOpenTransaction)
open class OpenTransaction : NSObject, FromDict {
    open let adId : String?
    open let transactionId : String?
    open let conversionTimestamp : String?
    open let reward : Reward?
    
    public var state : State = .ACTIVE
    
    public enum State {
        case ACTIVE
        case SENDING
        case SENT
        case ERROR
    }
    
    public required init(_ map: [String : Any]) {
        adId = map["adId"] as? String
        
        if let tid = map["transactionId"] as? NSNumber {
            transactionId = tid.stringValue
        }
        else {
            transactionId = nil
        }
        
        conversionTimestamp = map["conversionTimestamp"] as? String
        
        if let rewardMap = map["reward"] as? [String:Any] {
            reward = Reward(rewardMap)
        }
        else {
            reward = nil
        }
    }
    
    override open var hashValue: Int {
        return (transactionId!+adId!).hashValue
    }
    
    open override var description: String {
        guard let tid = transactionId, let aid = adId
            else { return "OpenTransaction" }
        return "OpenTransaction \(tid) for ad \(aid)"
    }
    
    @nonobjc
    public static func ==(lhs: OpenTransaction, rhs: OpenTransaction) -> Bool {
        return lhs.adId == rhs.adId && lhs.transactionId == rhs.transactionId
    }
}
