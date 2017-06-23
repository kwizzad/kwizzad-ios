//
//  KwizzadExampleUITests.swift
//  KwizzadExampleUITests
//
//  Created by Fares Ben Hamouda on 23.05.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import XCTest
import KwizzadSDK

class KwizzadExampleUITests: XCTestCase {
    
    let kwizzad = KwizzadSDK.instance
    let app = XCUIApplication()

    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        app.launch()
        
    }

    func testPlayAd() {
        

        // opening the Ad after preloading
        let webView =  app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element
        
        // waiting ( some delay) : expect to open webview
        let exists = NSPredicate(format: "exists == 1")
        
        expectation(for: exists, evaluatedWith: webView, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
        
        webView.tap()
        
        // Answering quizz
        let firstQuizzButton = app.buttons.allElementsBoundByAccessibilityElement[1]
        firstQuizzButton.tap()
        app.tap()

        let secondQuizzButton = app.buttons.allElementsBoundByAccessibilityElement[1]
        secondQuizzButton.tap()
        app.tap()
        
        let thirdQuizzButton = app.buttons.allElementsBoundByAccessibilityElement[2]
        thirdQuizzButton.tap()
        app.tap()
        
        let fourthQuizzButton = app.buttons.allElementsBoundByAccessibilityElement[1]
        fourthQuizzButton.tap()
        app.tap()
        
        app.tap()
        
        // tap Close icon
        let element = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element
        element.children(matching: .button).element.tap()
        
        app.alerts.buttons["Yay!"].tap()

    }
    
}
