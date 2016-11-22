//
//  OpenTransactionsSignal.swift
//  KwizzadSDK
//
//  Created by Anatol Ulrich on 30/10/2016.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

@objc
public protocol IOpenTransactionsSignal : ISignal {
    func subscribe(_ callback: @escaping (Set<OpenTransaction>) -> Void) -> NSObject;
}

open class OpenTransactionsSignal : Signal<Set<OpenTransaction>>, IOpenTransactionsSignal {
    open func subscribe(_ callback: @escaping (Set<OpenTransaction>) -> Void) -> NSObject {
        return super._subscribe(callback)
    }
}
