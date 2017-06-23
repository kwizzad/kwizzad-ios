//
//  WKController.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import WebKit

class WKController : NSObject, WKScriptMessageHandler, WKNavigationDelegate {

    let model : PlacementModel
    let api : KwizzadAPI
    var attached: Bool = true
    var isGoalUrlConditionInverted = true
    var dismissOnGoalUrl = true
    var goalReached = false
    var shouldTrackGoalUrl = true


    init(_ model: PlacementModel, _ api: KwizzadAPI) {
        self.model = model
        self.api = api;
    }

    open func detach() {
        attached=false;
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let transitionToCall2ActionClicked = { () -> Void in
            self.model.transition(
                from: AdState.SHOWING_AD, AdState.CALL2ACTION, AdState.CALL2ACTIONCLICKED,
                decideTo: {
                    self.goalReached = true;
                    if self.dismissOnGoalUrl == true {
                        return AdState.DISMISSED
                    }
                    return nil
            })
        }
        
        if attached {
            let urlString = webView.url!.absoluteString
            
            // TVSDK-398
            if urlString.contains("offer=not_available") {
                self.goalReached = true;
                self.shouldTrackGoalUrl = false;
            }

            if (model.goalUrl != nil && urlString.contains(model.goalUrl!) == isGoalUrlConditionInverted) {
                logger.logMessage("attached: \(self.attached) goal: \(self.model.goalUrl!) now: \(webView.url!)")
                transitionToCall2ActionClicked()
            }

            // Open App Store (url schema)
            if (navigationAction.request.url?.scheme?.contains("itms"))! {
                UIApplication.shared.openURL(navigationAction.request.url!)
                transitionToCall2ActionClicked()
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow);
    }


    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        KwizzadProgressView.shared.hideProgressView()
        if(self.goalReached) {
            logger.logMessage("goal reached");

            DispatchQueue.main.async {
                self.model.transition(from: AdState.CALL2ACTION, AdState.CALL2ACTIONCLICKED, to: AdState.GOAL_REACHED)
            }

            if shouldTrackGoalUrl {
                _ = self.api.queue(AdTrackingEvent(action: "goalReached", forAd: self.model.adResponse!.adId!))
            }
        }
        KwizzadProgressView.shared.hideProgressView()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "KwizzAdJI" && attached) {
            DispatchQueue.main.async {
                let data = message.body as! NSDictionary
                let event = data["event"] as! String
                let arguments = data["arguments"] as! NSArray

                logger.logMessage("received KwizzadJI message \(event) with arguments \(arguments)")

                switch(event) {
                case "challengeReady":
                    _ = self.api.queue(AdTrackingEvent(action: "adLoaded", forAd: self.model.adResponse!.adId!))
                    self.model.transition(from: AdState.LOADING_AD, to: AdState.AD_READY)

                case "call2Action":
                    self.model.transition(from: AdState.SHOWING_AD, to: AdState.CALL2ACTION)

                case "call2ActionClicked":
                    self.model.transition(from: AdState.CALL2ACTION, to: AdState.CALL2ACTIONCLICKED)
                    KwizzadProgressView.shared.hideProgressView()

                case "challengeCompleted":
                    if let num = arguments[0] as? Int {
                        if num >= 0 {
                            _ = self.api.queue(AdTrackingEvent(action: "challenge\(num)completed", forAd: self.model.adResponse!.adId!))
                            self.model.currentStep = num + 1;
                        }
                    }
                    break

                case "goalurl":
                    if let goal = arguments[0] as? String {
                        self.applyGoalUrl(goal)
                    }

                case "detach":
                    self.attached = false

                case "finished":
                    self.model.transition(to: AdState.DISMISSED)

                default:
                    logger.logMessage("unhandled message from KwizzadJI")
                }
            }
        }
    }

    func applyGoalUrl(_ goalUrlPattern: String) {
        logger.logMessage("received goal url pattern: \(goalUrlPattern)")

        self.model.goalUrl = goalUrlPattern

        self.dismissOnGoalUrl = true

        if model.goalUrl!.hasPrefix("OK") {
            model.goalUrl = model.goalUrl!.substring(from: model.goalUrl!.index(model.goalUrl!.startIndex, offsetBy: 2))
            self.dismissOnGoalUrl = false
        }

        self.isGoalUrlConditionInverted = true;
        if model.goalUrl!.hasPrefix("!") {
            model.goalUrl = model.goalUrl!.substring(from: model.goalUrl!.index(after: model.goalUrl!.startIndex))
            self.isGoalUrlConditionInverted = false
        }

        logger.logMessage("has goal URL: \(String(describing: self.model.goalUrl)), dismissOnGoalUrl: \(self.dismissOnGoalUrl), isGoalUrlConditionInverted: \(self.isGoalUrlConditionInverted)")
    }
}
