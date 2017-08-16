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

    @IBAction func enableAutomaticPreload(_ sender: UISwitch) {
        kwizzad.preloadAdsAutomatically = sender.isOn
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
        self.log("Potential rewards: \(rewardSummary ?? "Unknown")")
        
        adView.headlineLabel.text = adMetaInfo.headline ?? "Play a quiz!";
        adView.detailsLabel.text = incentiveText ?? "";
        
        // Handling the case where there's no potential rewards.
        if let reward =  Reward.summarize(rewards: potentialRewards).first {
            adView.smilesLabel.isHidden = false
            adView.smilesLabel.text = "+\(String(describing:reward.valueOrMaxValue()!.stringValue))"
        } else {
            adView.smilesLabel.isHidden = true
        }

        adView.layoutSubviews()
        self.height.constant = adView.preferredHeight()
        adView.layoutSubviews()
        
        if let expiry = adResponse.expiryInMilliseconds {
            self.log("Ad will expire in \(String(describing: (expiry/1000))) seconds.");
        }
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
        self.log("\(openTransactions.count) incoming transactions to be confirmed.");
        self.log("Got transactions: \(openTransactions.map({ $0.description }))");
        
        let rewards = openTransactions.flatMap({$0.reward })
        self.log("Earned rewards: \(Reward.enumerateRewardsAsText(rewards: rewards) ?? "(none)")");

        if rewards.count > 0 {
            let msg = Reward.confirmationText(rewards: rewards);
            let alert = UIAlertController(title: nil, message: msg, preferredStyle: UIAlertControllerStyle.alert);
            alert.addAction(UIAlertAction(title: "Yay!", style: UIAlertActionStyle.default, handler: { _ in
                openTransactions.forEach({ self.kwizzad.complete(transaction: $0) });
            }))
            self.present(alert, animated: true, completion: nil);
        } else {
            openTransactions.forEach({ self.kwizzad.complete(transaction: $0) }); // Silently confirm all transactions
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
