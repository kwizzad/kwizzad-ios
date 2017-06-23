//
//  OpenTransactionsEvent.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 20.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

open class OpenTransactionsEvent: KwizzadEvent, FromDict {
    
    open var transactions: [OpenTransaction]?
    
    public override required init(_ map: [String : Any]) {
        
        transactions = dictConvertToObject(arr: map["transactions"] as? [[String:Any]], type: OpenTransaction.self)
        
        super.init(map)
    }
}
