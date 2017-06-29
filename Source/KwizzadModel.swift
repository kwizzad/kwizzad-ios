//
//  KwizzadModel.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

// For client-side DNS load balancing.
let randomServerIndex = arc4random_uniform(3) + 1;


/// This holds the data needed to run a Kwizzad client.
class KwizzadModel {
    var apiKey: String?
    var configuredAPIBaseUrl: String?
    var serverIsOverridden = false;
    var overrideWeb:String?
    let installId: String;

    let configured = UnsafeVariable(false)

    let openTransactions : UnsafeVariable<Set<OpenTransaction>> = UnsafeVariable([])

    var placements = [String: PlacementModel]()

    let userData = UserDataModel();

    public init() {
        let userDefaults = UserDefaults.standard;
        
        if let ud = userDefaults.object(forKey: "KwizzadInstallID")  {
            installId = ud as! String
        } else {
            installId = UUID().uuidString
            userDefaults.setValue(installId, forKey: "KwizzadInstallID");
            userDefaults.synchronize();
        }

    }

    /// - returns the base URL to use to speak with Kwizzad's backend. This adds client-side load-balancing support for more stability.
    func apiBaseURL(apiKey: String) -> String {
        let apiKeyPrefix = apiKey.substring(to: apiKey.index(apiKey.startIndex, offsetBy: 7))
        return self.configuredAPIBaseUrl ?? "https://\(apiKeyPrefix)-\(randomServerIndex).api.kwizzad.com/api/sdk/";
    }

    /// - returns the placement model with the given placement ID, for example to observe its state.
    /// parameter placementId: The ID string of the placement you want to use. If you don't know which
    /// placement ID to use for Kwizzad, contact the Kwizzad team.
    func placementModel(placementId : String) -> PlacementModel {
        var pm = placements[placementId];
        if(pm == nil) {
            logger.logMessage("creating placement \(placementId)")
            pm = PlacementModel(placementId: placementId)
            placements[placementId] = pm
        }
        return pm!;
    }
}
