//
//  AppDelegate.swift
//  KwizzadExample
//
//  Created by Sandro Manke on 22.09.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import UIKit
import KwizzadSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        KwizzadSDK.setup(configuration: Configuration.create().apiKey("b81e71a86cf1314d249791138d642e6c4bd08240f21dd31811dc873df5d7469d").build())
        KwizzadSDK.instance.showDebugMessages = true // show debug messages
        return true
    }
}

