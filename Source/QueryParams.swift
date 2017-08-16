//
//  QueryParams.swift
//  KwizzadSDK
//
//  Created by Sebastian Felix on 15.08.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import Foundation
import AdSupport

/// Adds given params to the given URL's query string and returns the new URL.

func addQueryParams(url: URL, newParams: [URLQueryItem]) -> URL? {
    let urlComponents = NSURLComponents.init(url: url, resolvingAgainstBaseURL: false)
    guard urlComponents != nil else { return nil; }
    if (urlComponents?.queryItems == nil) {
        urlComponents!.queryItems = [];
    }
    urlComponents!.queryItems!.append(contentsOf: newParams);
    return urlComponents?.url;
}


/// Generates a 'slug' app store URL from the app's name.
///
/// Follows specification from https://developer.apple.com/library/ios/qa/qa1633/_index.html.
///
/// Ported to Swift from https://stackoverflow.com/a/22531085/387719

func generateAppStoreURL() -> URL? {
    if let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String {
        let appNameData = appName.replacingOccurrences(of: "&", with: "and")
            .data(using: String.Encoding.ascii, allowLossyConversion: true);
        if let bundleName = String.init(data: appNameData!, encoding: String.Encoding.ascii) {
            let range = bundleName.startIndex..<bundleName.endIndex;
            let invalidChars = "[!¡\"#$%'()*+,-./:;<=>¿?@\\[\\]\\^_`{|}~\\s\\t\\n]";
            let bundleNameSlug = bundleName.replacingOccurrences(
                of: invalidChars,
                with: "",
                options: String.CompareOptions.regularExpression,
                range: range
            ).lowercased()
            return URL.init(string: String.init(format: "https://appstore.com/%@", bundleNameSlug));
        }
    }
    return nil;
}


/// Adds query parameters that Komet can use for better targeting.

func addKometQueryParams(userData: UserDataModel, url: URL) -> URL? {
    let device = UIDevice.current
    let mainBundle = Bundle.main
    var params = [
        "device_make": "Apple",
        "device_model": device.model,
        "device_os": device.systemName,
        "device_osv": device.systemVersion,
        "app_bundle": mainBundle.bundleIdentifier!,
        "app_domain": mainBundle.bundleIdentifier!.components(separatedBy: ".").reversed().joined(separator: "."),
        "app_name": mainBundle.infoDictionary![kCFBundleNameKey as String] as! String,
    ];
    if userData.gender != Gender.Unknown {
        params["gender"] = userData.gender.description;
    }
    if let appStoreUrl = generateAppStoreURL() {
        params["app_storeurl"] = appStoreUrl.absoluteString;
    }
    if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
        params["device_ifa"] = ASIdentifierManager.shared().advertisingIdentifier.uuidString;
    }
    return addQueryParams(url: url, newParams: params.flatMap { URLQueryItem.init(name: $0, value: $1) })
}
