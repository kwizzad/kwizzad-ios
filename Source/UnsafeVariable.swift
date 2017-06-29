//
//  UnsafeVariable.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 03.02.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import Foundation

// NOT THREADSAFE! :)
public final class UnsafeVariable<Element> {
    
    public typealias E = Element
    
    private let _subject: BehaviorSubject<Element>
    
    // state
    private var _value: E
    
    /// Gets or sets current value of variable.
    ///
    /// Whenever a new value is set, all the observers are notified of the change.
    ///
    /// Even if the newly set value is same as the old value, observers are still notified for change.
    var value: E {
        get {
            return _value
        }
        set(newValue) {
            _value = newValue
            _subject.on(.next(newValue))
        }
    }
    
    /// Initializes variable with initial value.
    ///
    /// - parameter value: Initial variable value.
    init(_ value: Element) {
        _value = value
        _subject = BehaviorSubject(value: value)
    }
    
    /// - returns: Canonical interface for push style sequence
    func asObservable() -> Observable<E> {
        return _subject
    }
    
    deinit {
        _subject.on(.completed)
    }
}
