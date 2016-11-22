//
//  AdState.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

@objc
public protocol IAdStateSignal : ISignal {
    func subscribe(_ callback: @escaping (AdState) -> Void) -> NSObject;
}

open class AdStateSignal : Signal<AdState>, IAdStateSignal {
    
    open func subscribe(_ callback: @escaping (AdState) -> Void) -> NSObject {
        return super._subscribe(callback)
    }
}

@objc(KwizzadAdState)
public enum AdState : Int, CustomStringConvertible {
    /**
     * -> REQUESTING_AD
     */
    case INITIAL
    
    /**
     * We are currently requesting an ad.
     * <p>
     * -> RECEIVED_AD, NOFILL
     */
    case REQUESTING_AD
    
    /**
     * successful ad request, but no ad was available to be returned.
     */
    case NOFILL
    
    /**
     * -> LOADING_AD
     */
    case RECEIVED_AD
    
    /**
     * -> AD_READY
     */
    case LOADING_AD
    
    /**
     * Ad was loaded successfully and is ready to be shown.
     * <p>
     * ->  SHOWING_AD, DISMISSED
     */
    case AD_READY
    
    /**
     * -> CALL2ACTION, DISMISSED
     */
    case SHOWING_AD
    
    /**
     * -> GOAL_REACHED, DISMISSED
     */
    case CALL2ACTION
    
    /**
     * TODO:
     */
    case CALL2ACTIONCLICKED
    
    /**
     * shows OK button instead of X currently
     * <p>
     * -> DISMISSED
     */
    case GOAL_REACHED
    
    /**
     * Ad was closed.
     */
    case DISMISSED
    
    static let strings: [AdState:String] = [
        .INITIAL:"INITIAL",
        .REQUESTING_AD:"REQUESTING_AD",
        .NOFILL:"NOFILL",
        .RECEIVED_AD:"RECEIVED_AD",
        .LOADING_AD:"LOADING_AD",
        .AD_READY:"AD_READY",
        .SHOWING_AD:"SHOWING_AD",
        .CALL2ACTION:"CALL2ACTION",
        .CALL2ACTIONCLICKED:"CALL2ACTIONCLICKED",
        .GOAL_REACHED:"GOAL_REACHED",
        .DISMISSED:"DISMISSED"
    ]
    
    func string() -> String {
        if let str = AdState.strings[self] {
            return str
        }
        return "UNKNOWN"
    }
    
    public var description:String {
        get {
            return string()
        }
    }
}
