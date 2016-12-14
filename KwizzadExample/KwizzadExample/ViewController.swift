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
    // Optionally, you can use this method to close the ad.
    func stopAd() {
        KwizzadSDK.instance.close(self.placementId)
    }
    
    // Customize this to change how your app shows users their rewards.
    // Note that each open transaction must be confirmed by the app (using `completeTransaction`).
    // Unconfirmed transactions are shown again until they are confirmed.
    
    func handleTransaction(_ t:OpenTransaction) {
        print("Received transaction: \(t.adId) \(t.transactionId) \(t.state) \(t.conversionTimestamp), confirming...")

        if let reward = t.reward {
            var msg = "You've earned a reward!"
            if let amount = reward.amount, let currency = reward.currency {
                msg = "You've earned \(amount) \(currency)."
            }
            let alert = UIAlertController(title: "Congratulations!", message: msg, preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Yo", style: UIAlertActionStyle.default, handler: { foo in
                self.kwizzad.completeTransaction(t)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        else {
            // Silently confirm the transaction
            self.kwizzad.completeTransaction(t)
        }
    }
    
    @IBAction func startAd(_ sender: Any) {
        self.placementId = placementTx.text!;
        
        let adState = kwizzad.placementModel(placementId).adState;
        
        guard adState == .INITIAL || adState == .DISMISSED else {
            return
        }
        
        self.disposeBag = DisposeBag()
        self.controller = nil
        
        // For better targeting, you can set known user data here:
        let userData = kwizzad.userDataModel;
        userData.userId = "12345" // identifies the user inside your app
        userData.gender = Gender.Female
        userData.userName = "Francesca Rossi" // user name inside your app
        userData.facebookUserId = "1234abc"
        
        kwizzad.requestAd(self.placementId)
        
        kwizzad.placementModel(placementId).adStateObservable.subscribe(onNext: { adState in
            switch(adState) {
            case AdState.RECEIVED_AD:
                
                print("received ad :))")
                let myCustomParameters = ["userId":userData.userId]; // "userId" should be set to userData.userId
                self.controller = self.kwizzad.prepare(self.placementId, customParameters: myCustomParameters);
                
            case AdState.AD_READY:
                print("ad ready")
                
                self.present(self.controller!, animated: true, completion: {
                    print("presented")
                })
                
            case AdState.SHOWING_AD:
                print("showing ad now")
            case AdState.DISMISSED:
                print("dismissed")
                
                self.disposeBag = DisposeBag()
                
                KwizzadSDK.instance.pendingTransactions()
                    .subscribe(onNext: { transactions in
                        if let t = transactions.first {
                            self.handleTransaction(t);
                        }
                    })
                    .addDisposableTo(self.disposeBag)
                
            case AdState.NOFILL:
                let alert = UIAlertController(title: nil, message: "No ad available on this placement.", preferredStyle: UIAlertControllerStyle.alert)
                self.present(alert, animated: true)
                
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {
                    (alertAction: UIAlertAction!) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                
            default:
                print("other")
            }
        }).addDisposableTo(disposeBag)
    }
    
    
    @IBOutlet weak var placementTx: UITextField!

    // Contact us to get a valid placement ID for your app and fill it in here.
    var placementId: String = "goal_ok";
    
    let kwizzad = KwizzadSDK.instance;
    
    var disposeBag = DisposeBag()
    
    var controller : UIViewController?
}

