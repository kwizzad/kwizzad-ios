//
//  PlacementModel.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift

@objc(KwizzadPlacementModel)
open class PlacementModel : NSObject {
    
    let state = Variable(AdState.INITIAL)
    let closeType = Variable("OVERALL")
    let _closeButtonVisible = Variable(false)
    var _adResponse : AdResponseEvent?
    
    let disposeBag = DisposeBag()
    let placementId: String
    var _changed: Date = Date()
    var retryAfter:Date?
    var currentStep = 0
    var goalUrl:String? = nil
    
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
    
    open var closeButtonVisible: Bool {
        return _closeButtonVisible.value
    }
    
    open var closeButtonVisibleObservable: Observable<Bool> {
        return _closeButtonVisible.asObservable()
    }
    
    open func closeButtonVisibleSignal(_ callback: @escaping (Bool) -> Void) -> NSObject{
        return BoolSignal(closeButtonVisibleObservable).subscribe(callback);
    }
    
    open var adStateObservable : Observable<AdState> {
        return state.asObservable()
    }
    
    open func adStateSignal(_ callback: @escaping (AdState) -> Void) -> NSObject{
        return AdStateSignal(adStateObservable).subscribe(callback)
    }
    
    open var adState: AdState {
        get {
            return state.value
        }
        set(newValue) {
            kwlog.debug("changing adState from \(self.state.value) to \(newValue)")
            _changed = Date()
            state.value = newValue
        }
    }
    
    open var changed: Date {
        return _changed
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
                    
                    kwlog.debug("adstate changing from \(self.adState) to \(to)");
                    
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
