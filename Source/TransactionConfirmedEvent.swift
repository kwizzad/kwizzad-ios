//
//  TransactionConfirmedEvent.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

open class TransactionConfirmedEvent : AdEvent, ToDict {
    open var transactionId : String?
    
    static func fromTransaction(_ transaction: OpenTransaction) -> TransactionConfirmedEvent {
        let event = TransactionConfirmedEvent.init(type: "transactionConfirmed", placementId: nil, adId: transaction.adId)
        event.transactionId = transaction.transactionId
        return event
    }
    
    open override func toDict(_ map: inout [String : Any]) {
        super.toDict(&map)
        (transactionId, "transactionId") --> map
    }
    
}
