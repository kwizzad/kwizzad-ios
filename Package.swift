//
//  Package.swift
//  KwizzadSDK
//
//  Created by Fares Ben Hamouda on 07/06/2017.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KwizzadSDK",
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3)
    ],
    exclude: ["Tests", "Example"]
)
