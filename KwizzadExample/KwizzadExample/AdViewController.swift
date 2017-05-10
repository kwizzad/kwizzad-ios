//
//  AdViewController.swift
//  KwizzadExample
//
//  Created by Fares Ben Hamouda on 25.04.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import Foundation
import KwizzadSDK

class AdViewController: UIViewController, KwizzadSDKDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var collectionView: UICollectionView!

    let placements = ["cool0","cool1" , "cool2" , "cool3"]

    let kwizzad = KwizzadSDK.instance;
    
    var dictPlacements = [String : UIViewController?]()
    
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        kwizzad.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.row
        if (kwizzad.canShowAd(placementId:placements[index])) {
            
            guard let controller = self.dictPlacements[placements[indexPath.row]] else {
                return
            }
            self.present(controller!, animated: true, completion: {
                print("present")
            })
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return placements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell_adview",for: indexPath)
        
        let adView = cell.contentView.viewWithTag(1) as! AdView
        
        adView.detailsLabel.text = "Loading..."
        adView.headlineLabel.text = "Loading..."
        
        self.kwizzad.requestAd(placementId: placements[indexPath.row], onAdAvailable: { (rewards, adResponse) in
            
            // Same as kwizzadOnAdAvailable delegate function
            // don't use both as a time
            
            let adMetaInfo = adResponse?.adMetaInfo;
            let thumbnailWidth = 600;
            let thumbnailUrlString = adResponse?.squaredThumbnailURL(width: thumbnailWidth);
            
            let myCustomParameters : [String:Any] = [:]; // Optionally, you can supply custom parameters for special use cases here.
            
            let controller = self.kwizzad.loadAd(placementId: self.placements[indexPath.row], customParameters: myCustomParameters)
            print("index : ",indexPath.row)
            
            self.dictPlacements[self.placements[indexPath.row]] = controller
            
            adView.headlineLabel.text = adMetaInfo?.headline ?? "Play a quiz!";
            adView.detailsLabel.text = adMetaInfo?.teaser ?? "Play a quiz!";

            adView.sizeToFit()
            self.loadImage(imageView: adView.imageView,urlString: thumbnailUrlString)
        })

        return cell
    }

    func loadImage(imageView : UIImageView? , urlString: String?)  {
        if let urlString = urlString {
            if let url = URL(string: urlString) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            let image = UIImage(data: data)
                            imageView?.image = image
                        }
                    }
                }
            }
        }
    }

    /////////////////////////////////////////////////////////////////////
    //                                                                 //
    //  The following delegate methods are called by the Kwizzad SDK.  //
    //                                                                 //
    /////////////////////////////////////////////////////////////////////
    
    func kwizzadDidRequestAd(placementId: String) {
        print("Requested an ad on placement \(placementId).")
    }
    
    
    func kwizzadOnAdAvailable(placementId: String, potentialRewards: [Reward], adResponse: AdResponseEvent) {
        print("kwizzadOnAdAvailable on placement \(placementId).")
    }
    
    func kwizzadGotOpenTransactions(openTransactions: Set<OpenTransaction>) {
        print("\(openTransactions.count) incoming transactions to be confirmed.")
        for transaction in openTransactions {
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
    
    func kwizzadOnAdReady(placementId: String) {
    }
    
    func kwizzadDidShowAd(placementId: String) {
    }
    
    func kwizzadDidDismissAd(placementId: String) {
    }
    
    func kwizzadOnNoFill(placementId: String) {
    }
    
}
