//
//  AdState.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

/// A class holds the current state of the Ad.
@objc(KwizzadAdState)
public enum AdState : Int, CustomStringConvertible {
    /// Kwizzad has been initialized.
    case INITIAL
    
    /// Kwizzad is currently requesting an ad.
    case REQUESTING_AD

    /// Kwizzad requested an ad, but there was none available for the current placement.
    /// The system will retry at a later point.
    case NOFILL
    
    /// An ad has been received from the server.
    case RECEIVED_AD
    
    /// Kwizzad is loading the ad's information.
    case LOADING_AD
    
    /// Ad was loaded successfully and is ready to be shown.
    case AD_READY
    
    /// Ad is currently shown to the user.
    case SHOWING_AD
    
    /// User reached the call-to-action point (e.g. a download link).
    case CALL2ACTION
    
    /// User clicked on the call to action or reached an external website.
    case CALL2ACTIONCLICKED
    
    /// User reached the goal that was defined in the campaign.
    /// Instead of a normal close button, an affirmative button is shown
    /// to signalize the user that they can close the ad.
    case GOAL_REACHED
    
    /// The ad was dismissed. Kwizzad will load a new ad soon.
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
