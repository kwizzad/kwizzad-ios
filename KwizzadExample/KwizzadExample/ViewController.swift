//
//  ViewController.swift
//  KwizzadExample
//
//  Created by Sandro Manke on 22.09.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import UIKit
import KwizzadSDK
import RxSwift

class ViewController: UIViewController{
    
    func stopAd() {
        KwizzadSDK.instance.close(self.placementId)
    }
    
    @IBAction func startAd(_ sender: Any) {
        self.placementId = placementTx.text!;
        
        let adState = kwizzad.placementModel(placementId).adState;
        
        guard adState == .INITIAL || adState == .DISMISSED else {
            return
        }
        
        self.disposeBag = DisposeBag()
        self.controller = nil
        
        kwizzad.requestAd(self.placementId)
        
        kwizzad.placementModel(placementId).adStateObservable.subscribe(onNext: { adState in
            switch(adState) {
            case AdState.RECEIVED_AD:
                
                print("received ad :))")
                
                self.controller = self.kwizzad.prepare(self.placementId);
                
            case AdState.AD_READY:
                print("ad ready")
                
                self.present(self.controller!, animated: true, completion: {
                    print("presented")
                })
                
            case AdState.SHOWING_AD:
                print("showing ad now")
            case AdState.DISMISSED:
                print("fertig")
                
                self.disposeBag = DisposeBag()
                
                KwizzadSDK.instance.pendingTransactions()
                    .subscribe(onNext: { transactions in
                        if let t = transactions.first {
                            
                            let msg = "\(t.adId) \(t.transactionId) \(t.state) \(t.conversionTimestamp)"
                            
                            let alert = UIAlertController(title: "Transaction!", message: msg, preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "Yo", style: UIAlertActionStyle.default, handler: { foo in
                                self.kwizzad.completeTransaction(t)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    })
                    .addDisposableTo(self.disposeBag)
                
            case AdState.NOFILL:
                print("bääääh")
            default:
                print("other")
            }
        }).addDisposableTo(disposeBag)
    }
    
    @IBOutlet weak var placementTx: UITextField!

    var placementId: String = "tvsa";
    
    let kwizzad = KwizzadSDK.instance;
    
    var disposeBag = DisposeBag()
    
    var controller : UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

}

