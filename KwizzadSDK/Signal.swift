//
//  Signla.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 18.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift

@objc
public protocol IBoolSignal : ISignal {
    func subscribe(_ callback: @escaping (Bool) -> Void) -> NSObject;
}

open class BoolSignal : Signal<Bool>, IBoolSignal {
    
    open func subscribe(_ callback: @escaping (Bool) -> Void) -> NSObject {
        return super._subscribe(callback)
    }
}

@objc
public protocol ISignal {
    func addTo(_ disposeBag : SignalDisposeBag)
}

@objc
open class SignalDisposeBag : NSObject {
    fileprivate var _disposables = [NSObject]()
    
    open func add(_ disposable : NSObject) {
        _disposables.append(disposable);
    }
    
    deinit {
        _disposables.removeAll()
    }
}

open class Signal<Element> : NSObject, ISignal {
    
    let observable : Observable<Element>
    let bag = DisposeBag()
    
    public init(_ observable: Observable<Element>) {
        self.observable = observable;
        super.init();
        //kwlog.debug(">> created signal");
    }
    
    open func _subscribe(_ callback: @escaping (Element) -> Void) -> Signal<Element> {
        observable.subscribe(onNext: { el in
            
            callback(el)
            
        }).addDisposableTo(bag)
        return self
    }
    
    open func addTo(_ disposeBag : SignalDisposeBag) {
        disposeBag.add(self);
    }
    
}
