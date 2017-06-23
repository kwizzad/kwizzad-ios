//
//  KwizzadSDKDelegate.swift
//  KwizzadSDK
//
//  Created by Fares Ben Hamouda on 21/03/2017.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import Foundation


/// Delegate Callbacks for notifications after requesting an Ad.
///
/// Mandatory callbacks(The sequence of calls after an ad request should be as below)
/// - 1-kwizzadDidRequestAd:placementId
/// - 2-kwizzadOnAdAvailable:placementId:potentialRewards:adResponse
/// - 3-kwizzadOnAdReady:placementId
/// - 4-kwizzadDidShowAd:placementId
/// - 5-kwizzadGotOpenTransactions:placementId
/// - 6-kwizzadDidDismissAd:placementId
/// - 7-kwizzadOnNoFill:placementId

///
/// Optionals Callbacks: 
/// - kwizzadOnErrorOccured:placementId:reason
/// - kwizzadWillPresentAd:placementId
/// - kwizzadWillDismissAd:placementId
/// - kwizzadOnGoalReached:placementId
/// - kwizzadCallToActionClicked:placementId
@objc
public protocol KwizzadSDKDelegate : class {
    /// The user requested an ad.
    @objc func kwizzadDidRequestAd(placementId: String);
    /// An ad is available after the request.
    @objc func kwizzadOnAdAvailable(placementId: String, potentialRewards: [Reward], adResponse: AdResponseEvent);
    /// An ad is ready to play.
    @objc func kwizzadOnAdReady(placementId: String);
    /// An ad is already shown to the user.
    @objc func kwizzadDidShowAd(placementId: String);
    /// An ad has been dismissed.
    @objc func kwizzadDidDismissAd(placementId: String);
    /// Got transactions to be confirmed.
    @objc func kwizzadGotOpenTransactions(openTransactions : Set<OpenTransaction>, rewards: [Reward]) ;
    /// Got a nofill error during an ad request.
    @objc func kwizzadOnNoFill(placementId: String);
    
    /// An error occured with a reason.
    @objc optional func kwizzadOnErrorOccured(placementId: String, reason: String);
    /// An ad will be presented.
    @objc optional func kwizzadWillPresentAd(placementId: String);
    /// An ad will be dismissed.
    @objc optional func kwizzadWillDismissAd(placementId: String);
    /// An goal url has been reached.
    @objc optional func kwizzadOnGoalReached(placementId: String);
    /// CallToActionClicked has been reached.
    @objc optional func kwizzadCallToActionClicked(placementId: String);
}
