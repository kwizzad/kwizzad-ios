//
//  DebugViewController.swift
//  KwizzadExample
//
//  Created by Fares Ben Hamouda on 27.04.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import UIKit
import KwizzadSDK

class DebugViewController: UIViewController, KwizzadSDKDelegate, UITextFieldDelegate {
    let kwizzad = KwizzadSDK.instance;
    var kwizzadController : UIViewController?
    
    @IBOutlet var adView: AdView!
    @IBOutlet var debugMessage: UITextView!
    @IBOutlet var placementField: UITextField!
    @IBOutlet var height: NSLayoutConstraint!
    @IBOutlet var preloadButton: UIButton!

    override func viewDidLoad() {
        self.clearLog()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        kwizzad.delegate = self;
        self.preloadButtonPressed(self)
    }
    
    func loadImage(urlString: String?) {
        if let urlString = urlString {
            if let url = URL(string: urlString) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            let image = UIImage(data: data)
                            self.adView.imageView?.image = image
                        }
                    }
                }
            }
        }
    }

    @IBAction func startAd(_ sender: Any) {
        if (kwizzad.canShowAd(placementId:self.placementField.text!)) {
            guard let controller = self.kwizzadController else {
                return
            }
            self.present(controller, animated: true, completion: {
                self.log("Kwizzad controller presented.")
            })
        }
    }
    
    @IBAction func preloadButtonPressed(_ sender: Any) {
        self.clearLog()
        // Fade adview while preloading ad
        self.adView.alpha = 0.3
        self.adView.detailsLabel.text = "Loading..."
        self.adView.headlineLabel.text = "Loading..."
        preloadButton.isEnabled = false
        
        guard placementField.text != "" else {
            return
        }
        kwizzad.requestAd(placementId: placementField.text!)
        self.kwizzadController = nil
        view.endEditing(true)
    }

    func stopAd() {
        // Optionally, you can use this method to close the ad programmatically.
        KwizzadSDK.instance.close(placementField.text!)
    }

    /////////////////////////////////////////////////////////////////////
    //                                                                 //
    //  The following delegate methods are called by the Kwizzad SDK.  //
    //                                                                 //
    /////////////////////////////////////////////////////////////////////
    
    func kwizzadDidRequestAd(placementId: String) {
        self.log("Requested an ad on placement \(placementId).")
    }
    
    func kwizzadOnAdAvailable(placementId: String, potentialRewards: [Reward], adResponse: AdResponseEvent) {
        self.log("A new ad is available on placement \(placementId).")
        self.adView.isHidden = false

        // For better targeting, you can set known user data here:
        let userData = kwizzad.userDataModel;
        userData.userId = "12345" // identifies the user inside your app
        userData.gender = Gender.Female
        userData.userName = "Francesca Rossi" // user name inside your app
        userData.facebookUserId = "1234abc"

        let myCustomParameters : [String:Any] = [:]; // Optionally, you can supply custom parameters for special use cases here.
        self.kwizzadController = self.kwizzad.loadAd(placementId: placementId, customParameters: myCustomParameters)
        
        // Load the campaign image thumbnail in given given size, if possible.
        let thumbnailWidth = 400;
        let thumbnailUrlString = adResponse.squaredThumbnailURL(width: thumbnailWidth);
        self.loadImage(urlString: thumbnailUrlString)

        // If you want, you can also make use of the campaign's teaser text, headline and brand name.
        // All of these values are optional, so ensure your code works when they are `nil`.
        let adMetaInfo = adResponse.adMetaInfo;
        self.log("Brand name: \(adMetaInfo.brand ?? "(none)")");
        self.log("Teaser for campaign's content: \(adMetaInfo.teaser ?? "(none)")");

        let incentiveText = Reward.incentiveTextFor(rewards: potentialRewards)
        self.log("Incentive text: \(incentiveText ?? "(undefined)")")

        // Optionally, can use this to build your own strings that describe the potential reward(s).
        let rewardSummary = Reward.enumerateRewardsAsText(rewards: potentialRewards)
        self.log("Potential rewards: \(rewardSummary)")
        
        adView.headlineLabel.text = adMetaInfo.headline ?? "Play a quiz!";
        adView.detailsLabel.text = incentiveText ?? "";
        adView.smilesLabel.text = "+\(String(describing: Reward.summarize(rewards: potentialRewards).first!.valueOrMaxValue()!.stringValue))"
        adView.layoutSubviews()
        self.height.constant = adView.preferredHeight()
        adView.layoutSubviews()
        
        self.log("Ad will expire in \(String(describing: adResponse.expiry?.timeIntervalSinceNow)) seconds.");
    }

    func kwizzadOnAdReady(placementId: String) {
        self.log("The ad on placement \(placementId) is loaded / ready to be displayed.")
        self.adView.alpha = 1
        self.preloadButton.isEnabled = true
    }
    
    func kwizzadDidShowAd(placementId: String) {
        self.log("The ad on placement \(placementId) is shown.")
    }
    
    func kwizzadDidDismissAd(placementId: String) {
        self.log("The ad on placement \(placementId) has been dismissed.")
    }
    
    func kwizzadGotOpenTransactions(openTransactions: Set<OpenTransaction>) {
        self.log("\(openTransactions.count) incoming transactions to be confirmed.")
        for transaction in openTransactions {
            self.log(transaction.description)
            if let reward = transaction.reward {
                var msg = "You've earned a reward!"
                if let amount = reward.amount, let currency = reward.currency {
                    msg = "You've earned \(amount) \(currency)."
                }
                let alert = UIAlertController(title: "Congratulations!", message: msg, preferredStyle: UIAlertControllerStyle.alert)

                alert.addAction(UIAlertAction(title: "Yo", style: UIAlertActionStyle.default, handler: { foo in
                    self.kwizzad.complete(transaction: transaction)
                }))

                self.present(alert, animated: true, completion: nil)
            }
            else {
                self.kwizzad.complete(transaction: transaction) // Silently confirm the transaction
            }
        }
    }
    
    func kwizzadOnNoFill(placementId: String) {
        self.adView.isHidden = true
        self.preloadButton.isEnabled = true
        self.log("Received a no-fill response on placement \(placementId).");
    }
    
    // optional
    func kwizzadOnErrorOccured(placementId: String, reason: String) {
        self.log("An error occured on placement \(placementId). Reason : \(reason))");
        self.adView.isHidden = true
        self.preloadButton.isEnabled = true
    }
    
    // optional
    func kwizzadWillPresentAd(placementId: String) {
        self.log("Kwizzad will present an ad on placement \(placementId).");
    }
    
    // optional
    func kwizzadWillDismissAd(placementId: String) {
        self.log("Kwizzad will dismiss an ad on placement \(placementId).");
    }
    
    // optional
    func kwizzadOnGoalReached(placementId: String) {
        self.log("User reached the campaign goal on placement \(placementId).");
    }
    
    // optional
    func kwizzadCallToActionClicked(placementId: String) {
        self.log("User reached the call-to-action on placement \(placementId).");
    }
    
    /////////////////////////////////////////////////////////////////////
    
    // Hide keyboard when click return.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        preloadButtonPressed(self)
        textField.resignFirstResponder()
        return true;
    }
    
    // Hide keyboard when click outside.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        placementField.resignFirstResponder()
        self.view.endEditing(true)
    }
    
    func log(_ message: String) {
        let view = self.debugMessage!
        view.text.append("\n\n\(message)")
        let bottom = view.contentSize.height - view.bounds.size.height
        view.setContentOffset(CGPoint(x: 0, y: bottom), animated: true)
        print(message);
    }
    
    func clearLog() {
        self.debugMessage.text = "";
    }
}