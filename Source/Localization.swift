//
//  Localization.swift
//  KwizzadSDK
//
//  Created by Sebastian Felix on 18/05/2017.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import UIKit

var localizedBundle: Bundle? = nil;
let defaultLocale = "en";

/// Returns the language code with the country code removed (for example `"en"` if given `"en-GB"`.
/// returns: the language code with the country code removed (for example `"en"` if given `"en-GB"`.
func languageWithoutCountry(_ language: String) -> String {
    return language.count >= 2 ? language.substring(with: language.startIndex..<language.index(language.startIndex, offsetBy: 2)) : language;
}

func languageCodesToTry(_ preferredLanguages: [String]) -> [String] {
    let languages = preferredLanguages.flatMap({ [$0, languageWithoutCountry($0)] }) + [defaultLocale];
    var uniqueLanguages = Set<String>();
    return languages.filter({ uniqueLanguages.insert($0).inserted }); // filtering keeps input array order
}

func localizedBundle(_ languageCode: String) -> Bundle? {
    let mainBundle = Bundle(for: KwizzadSDK.self)
    if let path = mainBundle.path(forResource: languageCode, ofType: "lproj") {
        if let bundle = Bundle(path: path) {
            localizedBundle = bundle;
            return bundle;
        }
    }
    return nil;
}

/// Tries to find a localized bundle using the user's preferred languages.
/// Falls back to languages without countries if a bundle for the given language exists.
/// If none of the user's preferred languages exist as localization, it falls back to 'en'.
/// When using this, there MUST be a localization for "en", otherwise this crashes.
func findLocalizedBundle() -> Bundle? {
    if localizedBundle != nil { return localizedBundle!; }
    for languageCode in languageCodesToTry(Locale.preferredLanguages) {
        if let bundle = localizedBundle(languageCode) {
            return bundle;
        }
    }
    return nil;
}

/// returns: Translation of the given string format. When you use this, builds can automatically
///   collect new strings from the code in the build process using the `genstrings` tool.
func LocalizedString(_ format: String, comment: String) -> String {
    guard let bundle = findLocalizedBundle() else {
        print("Warning: No localized strings found for '\(defaultLocale)' locale!");
        return format;
    }
    
    return NSLocalizedString(format, tableName: "Kwizzad", bundle: bundle, comment: comment)
}
