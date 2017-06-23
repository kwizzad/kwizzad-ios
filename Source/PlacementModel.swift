//
//  PlacementModel.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift

/// Holds data for a *placement* and its state.
///
/// A placement can contain a specified set of campaigns and playout rules.
/// You get one or more placements assigned to use in your application.
/// Each placement has an ID so you can differentiate which set of
/// campaigns/playout rules is used in a specific place in your app.
///
/// Note: If you are unsure which placement ID to use, contact the Kwizzad
/// team to get a placement ID assigned.

@objc(KwizzadPlacementModel)
open class PlacementModel : NSObject {
    
    let state = UnsafeVariable(AdState.INITIAL)
    let closeType = UnsafeVariable("OVERALL")
    let _closeButtonVisible = UnsafeVariable(false)
    var _adResponse : AdResponseEvent?
    
    let disposeBag = DisposeBag()
    let placementId: String
    var _changed: Date = Date()
    var retryAfter:Date?
    var currentStep = 0
    var goalUrl:String? = nil

    /// Initializes a new placement with the given ID. You normally don't have to do call this yourself.
    public init(placementId: String) {
        self.placementId = placementId
        super.init();
        
        Observable.combineLatest(closeType.asObservable(), state.asObservable(),
                                 resultSelector: { (closeType, adState) -> Bool in
            switch (closeType) {
            case "AFTER_CALL2ACTION", "AFTER_CALL2ACTION_PLUS":
                return
                    (adState == AdState.CALL2ACTIONCLICKED
                        || adState == AdState.GOAL_REACHED);
                
            case "BEFORE_CALL2ACTION":
                return 
                    (adState == AdState.CALL2ACTION
                        || adState == AdState.CALL2ACTIONCLICKED
                        || adState == AdState.GOAL_REACHED);
            default: // OVERALL
                return true;
            }
        }).subscribe(onNext: {value in self._closeButtonVisible.value = value}).addDisposableTo(disposeBag)
        
        
    }
    
    open var adResponse : AdResponseEvent? {
        /// - returns the last ad response event received from the server.
        ///   You can use this to get information about potential rewards
        ///   for the end user, and for campaign details (for example to
        ///   display them in an ad button).
        get {
            return _adResponse;
        }
        set(newValue) {
            _adResponse = newValue;
            goalUrl = nil;
            if(adResponse?.closeButtonVisibility != nil) {
                closeType.value = _adResponse!.closeButtonVisibility!
            }
        }
    }

    open var adState: AdState {
        get {
            return state.value
        }
        set(newValue) {
            logger.logMessage("changing adState from \(self.state.value) to \(newValue)")
            _changed = Date()
            state.value = newValue
        }
    }

    open var adStateObservable : Observable<AdState> {
        return state.asObservable()
    }

    open var changed: Date {
        return _changed
    }
    
    open var closeButtonVisible: Bool {
        return _closeButtonVisible.value
    }

    open var closeButtonVisibleObservable: Observable<Bool> {
        return _closeButtonVisible.asObservable()
    }

    open func transition(_ to: AdState) {
        adState = to
    }
    
    @discardableResult open func transition(from: AdState..., to: AdState? = nil, decideTo: (() -> AdState?)? = nil, beforeChange: ((PlacementModel) -> Void)? = nil) -> Bool{
        for currentAdState in from {
            if adState == currentAdState {
                
                var changeTo = to;
                
                if let override = decideTo?() {
                    changeTo = override
                }
    
                beforeChange?(self)
                
                if(changeTo != nil) {
                    logger.logMessage("adstate changing from \(self.adState) to \(String(describing: to))");
                    
                    adState = changeTo!;
                }
                return true
            }
        }
        return false
    }
    
    func close() {
        self.transition(from: AdState.AD_READY,
                              AdState.LOADING_AD,
                              AdState.SHOWING_AD,
                              AdState.CALL2ACTION,
                              AdState.CALL2ACTIONCLICKED,
                              AdState.GOAL_REACHED,
                              AdState.NOFILL,
                          to: AdState.DISMISSED)

    }
}
