//
//  KwizzadSDK.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 22.09.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift
import XCGLogger

let kwlog: XCGLogger = {
    let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: true)
    
    // Create a destination for the system console log (via NSLog)
    /*let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")
    
    
    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = false
    systemDestination.showThreadName = true
    systemDestination.showLevel = false
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true
    systemDestination.showDate = true
    
    // Add the destination to the logger
    log.add(destination: systemDestination)*/
    
    return log
}()

func KwizzadLocalized(_ key: String, replacements : [String:String]? = nil) -> String {
    var str = NSLocalizedString(key, tableName: "Kwizzad", bundle: Bundle(for: type(of: KwizzadSDK.instance)), comment: key+"!");
    
    if let repl = replacements {
        
        for (key, value) in repl {
            str = str.replacingOccurrences(of: key, with: value);
        }
        
        return str;
    }
    else {
        return str;
    }
}

open class KwizzadSDK:NSObject {
    
    fileprivate static var TIMEOUT_REQUESTING_AD = 1000 * 10;
    
    @objc
    open static let instance = KwizzadSDK()
    
    let model = KwizzadModel()

    let api : KwizzadAPI
    
    let disposeBag = DisposeBag()
    
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
    
    open func configure(_ configuration : Configuration) {
        
        model.apiKey = configuration.apiKey;
        
        if(configuration.overrideServer != nil) {
            model.server = configuration.overrideServer!
        }
        
        model.overrideWeb = configuration.overrideWeb
        
        model.configured.value = true;
        
    }
    
    open var userDataModel: UserDataModel {
        return model.userData;
    }

    open var isConfigured: Bool {
        return model.configured.value;
    }
    
    open func requestAd(_ placementId: String) {
        let placement = model.placementModel(placementId: placementId)
        
        // TODO: check states
        
        switch(placement.adState) {
        case .REQUESTING_AD:
            if Int(placement.changed.timeIntervalSinceNow) > KwizzadSDK.TIMEOUT_REQUESTING_AD {
                kwlog.error("trying to request a new ad while currently ad request running. will be ignored.");
                return;
            } else {
                kwlog.info("placement was requesting ad, but timeout was reached");
            }
        case .RECEIVED_AD:
            kwlog.error("there is already an ad in received state, please use this first")
            return
        case .NOFILL:
            if let retryAfter = placement.retryAfter {
                kwlog.debug("retry after \(retryAfter.timeIntervalSinceNow)")
                if retryAfter.timeIntervalSinceNow < 0 {
                    kwlog.info("no fill said to retry after \(retryAfter)");
                    return
                }
            }
        default:
            break;
        }
        
        let adRequest = AdRequestEvent(placementId: placementId)
        
        placement.adState = AdState.REQUESTING_AD
        
        _ = api.queue(adRequest)
            .subscribe(onError: { err in
                placement.transition(from: AdState.REQUESTING_AD, to: AdState.DISMISSED)
            })
    }
    
    open func prepare(_ placementId : String, customParameters: [String:Any]? = nil) -> UIViewController? {
        kwlog.debug(placementId)
        
        let placement = model.placementModel(placementId: placementId)
        
        placement.currentStep = 0
        
        if(placement.transition(from: AdState.RECEIVED_AD, to: AdState.LOADING_AD)) {
            
            return KwizzadView.create(placement : placement, api : api, customParameters: customParameters);
        }
        return nil;
    }
    
    // helper function to dismiss ad without knowing or touching the view
    open func close(_ placementId : String) {
        kwlog.debug(placementId);
        let placement = model.placementModel(placementId: placementId)
        placement.close()
        
    }
    
    open func placementModel(_ placementId : String) -> PlacementModel {
        return model.placementModel(placementId: placementId)
    }
    
    open func pendingTransactions() -> Observable<Set<OpenTransaction>> {
        return model.openTransactions
            .asObservable()
            .map(self.filterActiveTransactions)
    }
    
    public func subscribeToPendingTransactions(callback: @escaping (Set<OpenTransaction>) -> Void) -> NSObject{
        let pending = pendingTransactions()
        //return AdStateSignal(adStateObservable).subscribe(callback);
        return OpenTransactionsSignal(pending).subscribe(callback)
    }
    
    fileprivate func filterActiveTransactions(_ input: Set<OpenTransaction>) -> Set<OpenTransaction> {
        
        kwlog.debug("open transactions changed \(input.count)")
        
        var filtered: Set<OpenTransaction> = []
        
        for cb in input {
            if cb.state == .ACTIVE {
                filtered.insert(cb)
            }
            else {
                kwlog.debug("filtering out \(cb)")
            }
        }
        return filtered;
    }
    
    public func completeTransaction(_ transaction: OpenTransaction) {
        transaction.state = .SENDING
        
        _ = api.queue(TransactionConfirmedEvent(transaction))
            .subscribe(onError: { err in
                transaction.state = .ERROR
            }, onCompleted: {
                kwlog.debug("transaction confirmed");
                transaction.state = .SENT
            })
    }
}

class KwizzadAPI {
    
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
                
                kwlog.debug("server response \(response)")
                kwlog.debug()
                
                let foo: [FromDict] = dictConvert(str: response)
                
                debugPrint(foo)
                
                for msg in foo {
                    
                    if let noFillEvent = msg as? NoFillEvent {
                        self.model
                            .placementModel(placementId: noFillEvent.placementId!)
                            .transition(from: .REQUESTING_AD,
                                        to: .NOFILL,
                                beforeChange: { placement in
                                    placement.retryAfter = noFillEvent.retryAfter;
                                    placement.adResponse = nil;
                            })
                    }
                    
                    if let openTransactionsEvent = msg as? OpenTransactionsEvent {
                        
                        kwlog.debug("got open transactions \(openTransactionsEvent.transactions)");
                        
                        if let transactions = openTransactionsEvent.transactions {
                            var newSet : Set<OpenTransaction> = [];
                            
                            for cb in self.model.openTransactions.value {
                                if transactions.contains(cb) && (cb.state == .ACTIVE || cb.state == .SENDING) {
                                    newSet.insert(cb);
                                }
                            }
                            
                            newSet.formUnion(transactions)
                            
                            kwlog.debug("size \(newSet.count)");
                            
                            if (newSet.count > 0 || newSet.count != self.model.openTransactions.value.count) {
                                kwlog.debug("changed, setting transactions");
                                self.model.openTransactions.value = newSet;
                            }
                        }
                    }
                    
                    if let adResponse = msg as? AdResponseEvent {
                        self.model.placementModel(placementId: adResponse.placementId!)
                            .transition(
                                from: AdState.REQUESTING_AD,
                                to: AdState.RECEIVED_AD,
                                beforeChange: { placement in
                                    placement.adResponse = adResponse;
                                    if self.model.overrideWeb != nil, adResponse.url != nil, let regex = try? NSRegularExpression(pattern: "[^:]+://[^/]+", options: .caseInsensitive) {
                                        
                                        kwlog.debug("url before \(adResponse.url)")
                                        adResponse.url = regex.stringByReplacingMatches(in: adResponse.url!, options: .withTransparentBounds, range: NSMakeRange(0, adResponse.url!.characters.count), withTemplate: self.model.overrideWeb!)
                                        kwlog.debug("url after \(adResponse.url)")
                                    }
                                    
                                    //QLog.d("Replace " + event.url + " with " + model.overrideWeb);
                                    //event.url = event.url.replaceFirst("",model.overrideWeb);
                                    //QLog.d("Replaced: " + event.url);
                                }
                        )
                        
                    }
                }
        }).addDisposableTo(disposeBag)
    }
    
    func send(_ request: String, _ ret: BehaviorSubject<Void>) -> Observable<String> {
        return Observable.create { (observer) -> Disposable in
            var task: URLSessionDataTask?
            
            let baseUrl = self.model.server+self.model.apiKey!+"/"+self.model.installId;
            
            let session = URLSession.shared
            
            kwlog.debug(baseUrl)
            kwlog.debug(request)
            
            var httpRequest = URLRequest(url: URL(string: baseUrl)!)
            httpRequest.httpMethod = "POST";
            httpRequest.httpBody = request.data(using: .utf8);
            
            kwlog.debug("sending \(httpRequest.httpBody)")
            
            httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type");
            
            task = session.dataTask(with: httpRequest) { (data, response, error) -> Void in
                if error != nil {
                    kwlog.debug(error)
                    observer.onError(error!)
                } else {
                    let result = String(data: data!, encoding:.utf8)!
                    observer.onNext(result);
                    observer.onCompleted()
                    ret.onCompleted()
                }
            }
            task?.resume()
            
            return Disposables.create {
                if task != nil {
                    task?.cancel()
                }
            }
            }.retryWhen{ error -> Observable<Int64> in
                return Observable.timer(30000, scheduler: MainScheduler.instance)
            }.catchError({ error in
                ret.onError(error)
                return Observable.just("")
            })
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
        kwlog.debug("queueing \(request)")
        
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
