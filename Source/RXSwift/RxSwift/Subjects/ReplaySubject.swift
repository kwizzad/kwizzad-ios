//
//  ReplaySubject.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 4/14/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

/// Represents an object that is both an observable sequence as well as an observer.
///
/// Each notification is broadcasted to all subscribed and future observers, subject to buffer trimming policies.
class ReplaySubject<Element>
    : Observable<Element>
    , SubjectType
    , ObserverType
    , Disposable {
    typealias SubjectObserverType = ReplaySubject<Element>
    
    /// Indicates whether the subject has any observers
    var hasObservers: Bool {
        _lock.lock()
        let value = _observers.count > 0
        _lock.unlock()
        return value
    }
    
    fileprivate let _lock = RecursiveLock()
    
    // state
    fileprivate var _isDisposed = false
    fileprivate var _isStopped = false
    fileprivate var _stoppedEvent = nil as Event<Element>? {
        didSet {
            _isStopped = _stoppedEvent != nil
        }
    }
    fileprivate var _observers = Bag<(Event<Element>) -> ()>()
    
    typealias DisposeKey = Bag<AnyObserver<Element>>.KeyType
    
    func unsubscribe(_ key: DisposeKey) {
        abstractMethod()
    }

    final var isStopped: Bool {
        return _isStopped
    }
    
    /// Notifies all subscribed observers about next event.
    ///
    /// - parameter event: Event to send to the observers.
    func on(_ event: Event<E>) {
        abstractMethod()
    }
    
    /// Returns observer interface for subject.
    func asObserver() -> SubjectObserverType {
        return self
    }
    
    /// Unsubscribe all observers and release resources.
    func dispose() {
    }

    /// Creates new instance of `ReplaySubject` that replays at most `bufferSize` last elements of sequence.
    ///
    /// - parameter bufferSize: Maximal number of elements to replay to observer after subscription.
    /// - returns: New instance of replay subject.
    static func create(bufferSize: Int) -> ReplaySubject<Element> {
        if bufferSize == 1 {
            return ReplayOne()
        }
        else {
            return ReplayMany(bufferSize: bufferSize)
        }
    }

    /// Creates a new instance of `ReplaySubject` that buffers all the elements of a sequence.
    /// To avoid filling up memory, developer needs to make sure that the use case will only ever store a 'reasonable'
    /// number of elements.
    static func createUnbounded() -> ReplaySubject<Element> {
        return ReplayAll()
    }
}

fileprivate class ReplayBufferBase<Element>
    : ReplaySubject<Element>
    , SynchronizedUnsubscribeType {
    
    func trim() {
        abstractMethod()
    }
    
    func addValueToBuffer(_ value: Element) {
        abstractMethod()
    }
    
    func replayBuffer<O: ObserverType>(_ observer: O) where O.E == Element {
        abstractMethod()
    }
    
    override func on(_ event: Event<Element>) {
        dispatch(_synchronized_on(event), event)
    }

    func _synchronized_on(_ event: Event<E>) -> Bag<(Event<Element>) -> ()> {
        _lock.lock(); defer { _lock.unlock() }
        if _isDisposed {
            return Bag()
        }
        
        if _isStopped {
            return Bag()
        }
        
        switch event {
        case .next(let value):
            addValueToBuffer(value)
            trim()
            return _observers
        case .error, .completed:
            _stoppedEvent = event
            trim()
            let observers = _observers
            _observers.removeAll()
            return observers
        }
    }
    
    override func subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == Element {
        _lock.lock()
        let subscription = _synchronized_subscribe(observer)
        _lock.unlock()
        return subscription
    }

    func _synchronized_subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == E {
        if _isDisposed {
            observer.on(.error(RxError.disposed(object: self)))
            return Disposables.create()
        }
     
        let anyObserver = observer.asObserver()
        
        replayBuffer(anyObserver)
        if let stoppedEvent = _stoppedEvent {
            observer.on(stoppedEvent)
            return Disposables.create()
        }
        else {
            let key = _observers.insert(observer.on)
            return SubscriptionDisposable(owner: self, key: key)
        }
    }

    func synchronizedUnsubscribe(_ disposeKey: DisposeKey) {
        _lock.lock()
        _synchronized_unsubscribe(disposeKey)
        _lock.unlock()
    }

    func _synchronized_unsubscribe(_ disposeKey: DisposeKey) {
        if _isDisposed {
            return
        }
        
        _ = _observers.removeKey(disposeKey)
    }
    
    override func dispose() {
        super.dispose()

        synchronizedDispose()
    }

    func synchronizedDispose() {
        _lock.lock()
        _synchronized_dispose()
        _lock.unlock()
    }

    func _synchronized_dispose() {
        _isDisposed = true
        _observers.removeAll()
    }
}

final class ReplayOne<Element> : ReplayBufferBase<Element> {
    private var _value: Element?
    
    override init() {
        super.init()
    }
    
    override func trim() {
        
    }
    
    override func addValueToBuffer(_ value: Element) {
        _value = value
    }

    override func replayBuffer<O: ObserverType>(_ observer: O) where O.E == Element {
        if let value = _value {
            observer.on(.next(value))
        }
    }

    override func _synchronized_dispose() {
        super._synchronized_dispose()
        _value = nil
    }
}

class ReplayManyBase<Element> : ReplayBufferBase<Element> {
    fileprivate var _queue: Queue<Element>
    
    init(queueSize: Int) {
        _queue = Queue(capacity: queueSize + 1)
    }
    
    override func addValueToBuffer(_ value: Element) {
        _queue.enqueue(value)
    }

    override func replayBuffer<O: ObserverType>(_ observer: O) where O.E == Element {
        for item in _queue {
            observer.on(.next(item))
        }
    }

    override func _synchronized_dispose() {
        super._synchronized_dispose()
        _queue = Queue(capacity: 0)
    }
}

final class ReplayMany<Element> : ReplayManyBase<Element> {
    private let _bufferSize: Int
    
    init(bufferSize: Int) {
        _bufferSize = bufferSize
        
        super.init(queueSize: bufferSize)
    }
    
    override func trim() {
        while _queue.count > _bufferSize {
            _ = _queue.dequeue()
        }
    }
}

final class ReplayAll<Element> : ReplayManyBase<Element> {
    init() {
        super.init(queueSize: 0)
    }
    
    override func trim() {
        
    }
}
