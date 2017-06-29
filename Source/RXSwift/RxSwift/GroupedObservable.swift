//
//  GroupedObservable.swift
//  RxSwift
//
//  Created by Tomi Koskinen on 01/12/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents an observable sequence of elements that have a common key.
struct GroupedObservable<Key, Element> : ObservableType {
    typealias E = Element

    /// Gets the common key.
    let key: Key

    private let source: Observable<Element>

    /// Initializes grouped observable sequence with key and source observable sequence.
    ///
    /// - parameter key: Grouped observable sequence key
    /// - parameter source: Observable sequence that represents sequence of elements for the key
    /// - returns: Grouped observable sequence of elements for the specific key
    init(key: Key, source: Observable<Element>) {
        self.key = key
        self.source = source
    }

    /// Subscribes `observer` to receive events for this sequence.
    func subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == E {
        return self.source.subscribe(observer)
    }

    /// Converts `self` to `Observable` sequence. 
    func asObservable() -> Observable<Element> {
        return source
    }
}
