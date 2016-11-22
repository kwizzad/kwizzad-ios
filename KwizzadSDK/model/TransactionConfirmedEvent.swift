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
    
    public init(_ transaction: OpenTransaction) {
        super.init(type: "transactionConfirmed", placementId: nil, adId: transaction.adId)
        transactionId = transaction.transactionId
    }
    
    open override func toDict(_ map: inout [String : Any]) {
        super.toDict(&map)
        (transactionId, "transactionId") --> map
    }
    
}
