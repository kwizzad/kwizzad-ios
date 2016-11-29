//
//  KwizzadModel.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift


class KwizzadModel {
    var apiKey: String?
    var server: String = "https://kwizzad.tvsmiles.tv/api/sdk/"
    var overrideWeb:String?
    let installId: String;
    
    let configured = Variable(false)
    
    let openTransactions : Variable<Set<OpenTransaction>> = Variable([])
    
    var placements = [String: PlacementModel]()

    let userData = UserDataModel();
    
    public init() {
        let userDefaults = UserDefaults.standard;
        
        // TODO: ggf nicht userdefaults nutzen ;)
        if let ud = userDefaults.object(forKey: "KwizzadInstallID")  {
            installId = ud as! String
        }
        else {
            installId = UUID().uuidString
            userDefaults.setValue(installId, forKey: "KwizzadInstallID");
            userDefaults.synchronize();
        }
        
    }
    
    func placementModel(placementId : String) -> PlacementModel {
        var pm = placements[placementId];
        if(pm == nil) {
            kwlog.debug("creating placement \(placementId)")
            kwlog.debug(placementId)
            pm = PlacementModel(placementId: placementId)
            placements[placementId] = pm
        }
        return pm!;
    }
}
