//
//  LocalizationTests.swift
//  KwizzadSDK
//
//  Created by Sebastian Felix on 31.05.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import XCTest
@testable import KwizzadSDK

class LocalizationTests: XCTestCase {
    func testBundleFound() {
        XCTAssert(findLocalizedBundle() != nil);
    }
    
    func testTriedLanguageCodes() {
        XCTAssert(languageCodesToTry(["en-GB", "de"]) == ["en-GB", "en", "de"]);
        XCTAssert(languageCodesToTry(["fr-CH", "de"]) == ["fr-CH", "fr", "de", "en"]);
    }
    
    func testAvailableLocales() {
        ["en", "de"].forEach { XCTAssert(localizedBundle($0) != nil) };
    }
}
