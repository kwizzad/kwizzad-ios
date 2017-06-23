//
//  OpenTransaction.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

/// Holds information about a reward that the user can earn, has earned, or has not earned
/// because there was an issue.
///
/// On requesting an ad and on ad dismissal, you get an information about if/how the user got
/// pending transactions for rewards. You can then display this information to your user—either
/// summarized or with a dialog for each single pending reward. As soon as your app confirms a
/// transaction, its reward will be paid out.
///
/// Transactions work like an inbox, so you might transactions again (asynchronously) until your
/// app confirms them.

@objc(KwizzadOpenTransaction)
open class OpenTransaction: NSObject, FromDict {
    open let adId : String?
    open let transactionId : String?
    open let conversionTimestamp : String?
    open let reward : Reward?
    
    public var state : State = .ACTIVE
    
    public enum State {
        /// The reward will be payed out on confirmation.
        case ACTIVE
        
        /// The transaction is being confirmed by the client.
        case SENDING
        
        /// The transaction has been confirmed.
        case SENT
        
        /// There was an error confirming the transaction.
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
