//
//  KwizzadSDK.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 22.09.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift

let logger = Logger.sharedInstance
public typealias AdAvailableCallback = (_ rewards: [Reward]?, _ adResponse: AdResponseEvent?) -> Void

/// Handles all delegate callbacks and operations within KwizzadSDK.
/// Note: This is a singleton.
open class KwizzadSDK : NSObject {
    fileprivate static let TIMEOUT_REQUESTING_AD = 1000 * 10;
    fileprivate static let MIN_SUPPORTED_OSVERSION = "8";
    fileprivate static let STATES_THAT_ALLOW_REQUESTS = [
        AdState.INITIAL,
        AdState.NOFILL,
        AdState.AD_READY, // after expiration
        AdState.DISMISSED,
        ];

    enum ResponseError: Error {
        case fatalError
        case retryableRequestError
    }
    
    // To ensure that only 1 request will be performed after retry time in noFill state
    fileprivate var isRequestAlreadyRetried = false

    /// The object that acts as the delegate of the Kwizzad SDK.
    /// The delegate must implement the `KwizzadSDKDelegate` protocol.
    /// The delegate object is called back for specific events, and
    /// can decide about the user flow.
    open weak var delegate: KwizzadSDKDelegate?

    @objc
    open static let instance = KwizzadSDK()

    let model = KwizzadModel()
    
    /// When set to `true` (recommended),
    /// - a new ad is preloaded when a currently open ad is closed
    /// - the SDK tries to load a new ad when there is currently no ad available
    /// You can set this to `false` if you want have exact control over when new ads are loaded.
    open var preloadAdsAutomatically = true
    
    open var isDebug = true

    fileprivate let api : KwizzadAPI

    fileprivate var observedPlacementIds : Set<String> = []

    fileprivate let disposeBag = DisposeBag()
    
    fileprivate override init() {
        let c = Convertibles.instance;
        c.add(clazz: AdResponseEvent.self, type: "adResponse")
        c.add(clazz: OpenTransactionsEvent.self, type: "openTransactions")
        c.add(clazz: DeprecatedResponse.self, type: "openCallbacks")
        c.add(clazz: NoFillEvent.self, type: "adNoFill")

        api = KwizzadAPI(model);
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always;

        super.init();
    }
    

    /// Configures the SDK's basic data that are necessary to function.
    /// - Parameter configuration: A set of options to be used by the SDK.
    @objc
    static open func setup(configuration : Configuration) {
        instance.model.apiKey = configuration.apiKey;
        if(configuration.overrideServer != nil) {
            instance.model.configuredAPIBaseUrl = configuration.overrideServer!
        }
        instance.isDebug = configuration.debug
        instance.model.overrideWeb = configuration.overrideWeb
        instance.model.configured.value = true;
    }
    
    /// Configures the SDK's basic data that are necessary to function.
    /// - Parameter apiKey: Ask support for an api key.
    @objc
    static open func setup(apiKey : String) {
        instance.model.apiKey = apiKey;
        instance.model.configured.value = true;
    }

    /// Returns a set of targeting data that is used when requesting new ads.
    /// - returns: `UserDataModel`, a set of targeting data.
    open var userDataModel: UserDataModel {
        return model.userData;
    }

    /// Requests an ad on a given placement. Allows to supply a callback when an ad is received for this request.
    ///
    /// - Parameter placementId: the placement id to request.
    /// - Parameter onAdAvailable: an optional completion handler called with information about the received ad,
    ///   and potential rewards for the user when reaching the goal of the campaign.
    ///
    /// Warning: The onAdAvailable function is called additionally to the delegate function `kwizzadOnAdAvailable`.
    /// Don't use both at the same time.
    open func requestAd(placementId: String, onAdAvailable: AdAvailableCallback? = nil) {
        
        guard SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(version: KwizzadSDK.MIN_SUPPORTED_OSVERSION) else {
            let errMessage = "Requests are avoided with devices lower than iOS \(KwizzadSDK.MIN_SUPPORTED_OSVERSION)";
            logger.logMessage("\(errMessage)",.Error);
            self.delegate?.kwizzadOnErrorOccured?(placementId: placementId, reason: errMessage)
            return;
        }

        let placement = model.placementModel(placementId: placementId)
        guard KwizzadSDK.STATES_THAT_ALLOW_REQUESTS.contains(placement.state.value) else {
            let errMessage = "Ignored ad request in state \(placement.state.value)";
            logger.logMessage(errMessage,.Error);
            self.delegate?.kwizzadOnErrorOccured?(placementId: placementId, reason: errMessage)
            return;
        }
        
        if (placement.adState == .AD_READY) {
            placement.close()
        }
        
        self.startObservingAdStateAndNotifyDelegate(placementId: placementId, onAdAvailable: onAdAvailable);
        let adRequest = AdRequestEvent(placementId: placementId)
        
        placement.adState = AdState.REQUESTING_AD
        
        _ = self.api.queue(adRequest)
            .subscribe(onError: { err in
                placement.transition(from: AdState.REQUESTING_AD, to: AdState.DISMISSED)
                self.delegate?.kwizzadOnErrorOccured?(placementId: placementId, reason: err.localizedDescription)
            })
    }

    /// Should be called when an ad becomes available (for example in the `kwizzadOnAdAvailable` event).
    ///
    /// Loads the available ad content and prepares a view controller to be presented to the user.
    ///
    /// - Parameter placementId: the used placement id.
    /// - Parameter customParameters: a `Dictionary` with additional custom parameters to optimize targeting.
    /// - returns: A `UIViewController` with the ad's content to present to the user if successful,
    ///   `nil` otherwise.
    open func loadAd(placementId: String, customParameters: [String:Any]? = [:]) -> UIViewController? {
        logger.logMessage(placementId,.Debug)

        let placement = model.placementModel(placementId: placementId)

        placement.currentStep = 0

        if(placement.transition(from: AdState.RECEIVED_AD, to: AdState.LOADING_AD)) {
//            let myCustomParameters = ["userId": self.userDataModel.userId];
            return KwizzadViewController.create(placement : placement, api : api, customParameters: customParameters);
        }
        return nil;
    }
    
    /// Helper function to dismiss ads from the outside while they are open.
    /// Note: It's very uncommon that this is necessary.
    /// - Parameter placementId: the ID of the placement whose ad should be closed.
    open func close(_ placementId: String) {
        logger.logMessage(placementId);
        let placement = model.placementModel(placementId: placementId)
        placement.close()

    }

    /// - returns: `true` if the ad on the placement with the given ID can now be displayed, `false` otherwise.
    /// - Parameter placementId: the used placement id.
    open func canShowAd(placementId: String) -> Bool {
        let placement = model.placementModel(placementId: placementId)
        guard let adResponse = placement.adResponse else { return false; }
        return placement.adState == .AD_READY && !adResponse.adWillExpireSoon();
    }

    /// - returns: information and current state of the placement with the given ID.
    /// - Parameter placementId: identifies the placement.
    open func placementModel(placementId: String) -> PlacementModel {
        return model.placementModel(placementId: placementId)
    }

    /// Tells the backend to complete given transaction and trigger payout.
    /// - Parameter transaction: the transaction to complete.
    public func complete(transaction: OpenTransaction) {
        transaction.state = .SENDING

        _ = api.queue(TransactionConfirmedEvent.fromTransaction(transaction))
            .subscribe(onError: { err in
                transaction.state = .ERROR
            }, onCompleted: {
                logger.logMessage("transaction confirmed");
                transaction.state = .SENT
            })
    }

    // - returns: `true` if the SDK is already configured, `false` otherwise.
    fileprivate var isConfigured: Bool {
        return model.configured.value;
    }
    
    
    fileprivate func startObservingAdStateAndNotifyDelegate(placementId: String, onAdAvailable: AdAvailableCallback?) {
        let placement = model.placementModel(placementId: placementId)
        guard !observedPlacementIds.contains(placementId) else {
            return
        }
        
        observedPlacementIds.insert(placementId)
        
        placement.adStateObservable.subscribe(onNext: { adState in
            switch(adState) {
            case .REQUESTING_AD:
                self.delegate?.kwizzadDidRequestAd(placementId: placementId);
                if Int(placement.changed.timeIntervalSinceNow) > KwizzadSDK.TIMEOUT_REQUESTING_AD {
                    logger.logMessage("trying to request a new ad while currently ad request running. will be ignored.", .Error);
                    let errorMessage = "placement was requesting ad, but timeout was reached";
                    self.delegate?.kwizzadOnErrorOccured?(placementId: placement.placementId, reason: errorMessage);
                }
                return;
            case .LOADING_AD:
                logger.logMessage("LOADING_AD");
                return;
            case .RECEIVED_AD:
                logger.logMessage("RECEIVED_AD");
                if let adResponse = placement.adResponse {
                    let rewards = adResponse.rewards ?? []
                    self.delegate?.kwizzadOnAdAvailable(placementId: placementId, potentialRewards: rewards, adResponse: adResponse);
                    onAdAvailable?(rewards, adResponse)
                } else {
                    let errorMessage = "Got a RECEIVED_AD event with an empty ad response.";
                    self.delegate?.kwizzadOnErrorOccured?(placementId: placement.placementId, reason: errorMessage);
                }
                return
            case .AD_READY:
                logger.logMessage("AD_READY");
                self.delegate?.kwizzadOnAdReady(placementId: placementId);
                self.preloadAdIfEnabled(placement: placement);
                // Enabling nofill automatic request 
                self.isRequestAlreadyRetried = false;
                return;
            case .SHOWING_AD:
                logger.logMessage("SHOWING_AD");
                self.delegate?.kwizzadDidShowAd(placementId: placementId);
                return;
            case .DISMISSED:
                logger.logMessage("DISMISSED");
                self.delegate?.kwizzadDidDismissAd(placementId: placementId);
                self.preloadAdIfEnabled(placement: placement);
            case .NOFILL:
                self.delegate?.kwizzadOnNoFill(placementId: placementId);
                if let retryAfter = placement.retryAfter {
                    logger.logMessage("Retrying after \(retryAfter.timeIntervalSinceNow)",.Debug)
                    if (!self.isRequestAlreadyRetried) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter.timeIntervalSinceNow) {
                            self.isRequestAlreadyRetried = true
                            self.requestAd(placementId: placement.placementId)
                        }
                    }

                }
            default:
                break;
            }
        })
        .addDisposableTo(disposeBag);
    }
    
    func preloadAdIfEnabled(placement: PlacementModel?) {
        guard let placement = placement else { return; }
        if (self.preloadAdsAutomatically) {
            if (placement.adResponse?.adWillExpireSoon() ?? false) {
                self.requestAd(placementId: placement.placementId)
            }
        }
    }
    
    fileprivate func filterActiveTransactions(_ input: Set<OpenTransaction>) -> Set<OpenTransaction> {
        var filtered: Set<OpenTransaction> = []
        
        for cb in input {
            if cb.state == .ACTIVE {
                filtered.insert(cb)
            }
            else {
                logger.logMessage("filtering out \(cb)")
            }
        }
        return filtered;
    }
    fileprivate func SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(version: String) -> Bool {
        return UIDevice.current.systemVersion.compare(version,options: NSString.CompareOptions.numeric) != ComparisonResult.orderedAscending
        
    }

}
