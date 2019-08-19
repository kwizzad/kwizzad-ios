//
//  KwizzadAPI.swift
//  KwizzadSDK
//
//  Created by Fares Ben Hamouda on 21/03/2017.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift

class KwizzadAPI {
    
    fileprivate static let MAX_REQUEST_RETRIES = 10;
    let model : KwizzadModel;
    let disposeBag = DisposeBag();
    
    let sendQueue = PublishSubject<(String, BehaviorSubject<Void>)>();
    
    public init(_ model: KwizzadModel) {
        self.model = model;
        
        sendQueue
            .flatMap(self.send)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { response in
                
                if(response == "") {
                    return
                }
                
                logger.logMessage("Raw server response: \(response)")
                
                let responseEvents: [FromDict] = dictConvert(str: response)
                
                debugPrint("Response events:", responseEvents)
                
                for responseEvent in responseEvents {
                    if let noFillEvent = responseEvent as? NoFillEvent {
                        self.model
                            .placementModel(placementId: noFillEvent.placementId!)
                            .transition(from: .REQUESTING_AD,
                                        to: .NOFILL,
                                        beforeChange: { placement in
                                            placement.retryAfter = noFillEvent.retryAfter;
                                            placement.retryInMilliseconds = noFillEvent.retryInMilliseconds;
                                            placement.adResponse = nil;
                            })
                    }
                    
                    if let openTransactionsEvent = responseEvent as? OpenTransactionsEvent {
                        logger.logMessage("got open transactions \(String(describing: openTransactionsEvent.transactions))");
                        
                        if let transactions = openTransactionsEvent.transactions {
                            var newSet : Set<OpenTransaction> = [];
                            
                            for cb in self.model.openTransactions.value {
                                if transactions.contains(cb) && (cb.state == .ACTIVE || cb.state == .SENDING) {
                                    newSet.insert(cb);
                                }
                            }
                            
                            newSet.formUnion(transactions)
                            
                            logger.logMessage("size \(newSet.count)");
                            
                            if (newSet.count > 0 || newSet.count != self.model.openTransactions.value.count) {
                                logger.logMessage("changed, setting transactions");
                                self.model.openTransactions.value = newSet;
                                // todo
                                KwizzadSDK.instance.delegate?.kwizzadGotOpenTransactions(
                                    openTransactions: self.model.openTransactions.value
                                )
                            }
                        }
                    }
                    
                    if let adResponse = responseEvent as? AdResponseEvent {
                        self.model.placementModel(placementId: adResponse.placementId!)
                            .transition(
                                from: AdState.REQUESTING_AD,
                                to: AdState.RECEIVED_AD,
                                beforeChange: { placement in
                                    placement.adResponse = adResponse;
                                    if self.model.overrideWeb != nil, adResponse.url != nil, let regex = try? NSRegularExpression(pattern: "[^:]+://[^/]+", options: .caseInsensitive) {
                                        
                                        logger.logMessage("url before \(String(describing: adResponse.url))")
                                        adResponse.url = regex.stringByReplacingMatches(in: adResponse.url!, options: .withTransparentBounds, range: NSMakeRange(0, adResponse.url!.count), withTemplate: self.model.overrideWeb!)
                                        logger.logMessage("url after \(String(describing: adResponse.url))")
                                    }
                            }
                        )
                        
                    }
                }
            }).addDisposableTo(disposeBag)
    }
    
    func isRegardedAsErroneous(response: HTTPURLResponse?) -> Bool {
        guard let response = response else { return true; }
        let statusCode = response.statusCode;
        logger.logMessage("Status code: \(statusCode)")
        // Note that we do not handle redirections yet, so we regard them as errors.
        return statusCode >= 300;
    }
    
    func shouldRetryRequest(response: HTTPURLResponse?) -> Bool {
        guard let response = response else { return false; }
        let statusCode = response.statusCode;
        // 499 is nginx-y for a backend timeout, 500+ is reserved for server-side errors.
        // We regard these as retry-able because probably we just have to wait for a backend
        // to be available again later.
        // Response errors < 499 mean errors on our side, so we won't retry the according requests.
        return statusCode >= 499;
    }
    
    func retryTimeoutFor(index: Int, error: Swift.Error) -> TimeInterval? {
        guard error as? KwizzadSDK.ResponseError == KwizzadSDK.ResponseError.retryableRequestError else {
            return nil
        }
        let retryTimesInMinutes: [Int: TimeInterval] = [0:1.0, 1:5.0, 2:10.0, 3:60.0, 4:360.0, 5: 1440.0]
        let timeoutInSeconds = retryTimesInMinutes[min(index, retryTimesInMinutes.count - 1)]! * 60.0
        let randomAdditionalTimeout = timeoutInSeconds * Double(arc4random()) / Double(UINT32_MAX)
        return 0.5 * timeoutInSeconds + randomAdditionalTimeout
    }
    
    func send(_ request: String, _ ret: BehaviorSubject<Void>) -> Observable<String> {
        return Observable.create { (observer) -> Disposable in
            var task: URLSessionDataTask?
            
            let url = self.model.apiBaseURL(apiKey: self.model.apiKey!) + self.model.apiKey! + "/" + self.model.installId;
            let session = URLSession.shared
            
            logger.logMessage("POST \(url): \(request)")
            
            var httpRequest = URLRequest(url: URL(string: url)!)
            httpRequest.httpMethod = "POST";
            httpRequest.httpBody = request.data(using: .utf8);
            
            logger.logMessage("sending \(String(describing: httpRequest.httpBody))")
            
            httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type");
            
            task = session.dataTask(with: httpRequest) { (data, response, error) -> Void in
                if error != nil {
                    logger.logMessage("Error while handling HTTP request: \(String(describing: error))")
                    observer.onError(error!)
                    return
                }
                if (self.isRegardedAsErroneous(response: (response as? HTTPURLResponse))) {
                    let error = (self.shouldRetryRequest(response: response as? HTTPURLResponse)) ? KwizzadSDK.ResponseError.retryableRequestError : KwizzadSDK.ResponseError.fatalError
                    logger.logMessage("Response had an error (\(error)).")
                    observer.onError(error)
                    return
                }
                let result = String(data: data!, encoding:.utf8)!
                logger.logMessage("Response data: \(result)")
                observer.onNext(result);
                observer.onCompleted()
                ret.onCompleted()
            }
            task?.resume()
            
            return Disposables.create {
                if task != nil {
                    task?.cancel()
                }
            }
            }
            .retryWhen { errorObservable -> Observable<Int64> in
                return errorObservable.flatMapWithIndex({ (error, index) -> Observable<Int64> in
                    let seconds = self.retryTimeoutFor(index: index, error: error)
                    guard seconds != nil && index < KwizzadAPI.MAX_REQUEST_RETRIES else {
                        return Observable.error(error)
                    }
                    logger.logMessage("Retry #\(index) after \(seconds!)s")
                    return Observable<Int64>.timer(5, scheduler: MainScheduler.instance)
                })
            }
            .catchError { error in
                ret.onError(error)
                return Observable.just("")
        }
    }
    
    func convert<T:ToDict>(_ request : [T]) throws -> String {
        var str = "[";
        var first: Bool = true
        for r in request {
            if(first) {
                first = false;
            }
            else {
                str += ","
            }
            if let foo : String = dictConvert(r) {
                str += foo;
            }
        }
        str += "]"
        return str
    }
    
    func queue<T:ToDict>(_ request: T...) -> Observable<Void> {
        logger.logMessage("queueing \(request)")
        
        do {
            
            let ret = BehaviorSubject<Void>(value: Void())
            
            let r = try convert(request)
            
            sendQueue.onNext((r, ret))
            
            return ret.observeOn(MainScheduler.instance);
            
        }
        catch {
            return Observable.error(error);
        }
        
        
    }
    
}
