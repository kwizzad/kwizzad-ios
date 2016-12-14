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
    var goalUrlCondition = true
    var dismissOnGoalUrl = true
    var goalReached = false
    
    init(_ model: PlacementModel, _ api: KwizzadAPI) {
        self.model = model
        self.api = api;
    }
    
    open func detach() {
        attached=false;
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if(attached) {
            
            if (model.goalUrl != nil && webView.url!.absoluteString.contains(model.goalUrl!) == goalUrlCondition) {
                
                kwlog.debug("attached: \(self.attached) goal: \(self.model.goalUrl!) now: \(webView.url!)")
                
                model.transition(
                    from: AdState.SHOWING_AD, AdState.CALL2ACTION, AdState.CALL2ACTIONCLICKED,
                    decideTo: {
                        self.goalReached=true;
                        if self.dismissOnGoalUrl == true {
                            return AdState.DISMISSED
                        }
                        return nil
                })
                
                
            }
        }
        
        decisionHandler(.allow);
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if(self.goalReached) {
            kwlog.debug("goal reached");
            
            DispatchQueue.main.async {
                self.model.transition(from: AdState.CALL2ACTION, AdState.CALL2ACTIONCLICKED, to: AdState.GOAL_REACHED)
            }
            
            _ = self.api.queue(AdTrackingEvent(action: "goalReached", forAd: self.model.adResponse!.adId!))
            
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "KwizzAdJI" && attached) {
            
            DispatchQueue.main.async {
                let data = message.body as! NSDictionary
                let event = data["event"] as! String
                let arguments = data["arguments"] as! NSArray
                
                kwlog.debug("js msg received \(event) with arguments \(arguments)")
                
                switch(event) {
                case "challengeReady":
                    
                    _ = self.api.queue(AdTrackingEvent(action: "adLoaded", forAd: self.model.adResponse!.adId!))
                    
                    self.model.transition(from: AdState.LOADING_AD, to: AdState.AD_READY)
                    
                case "call2Action":
                    self.model.transition(from: AdState.SHOWING_AD, to: AdState.CALL2ACTION)
                    
                case "call2ActionClicked":
                    self.model.transition(from: AdState.CALL2ACTION, to: AdState.CALL2ACTIONCLICKED)
                    
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
                    kwlog.debug("unhandled message")
                }
            }
        }
    }
    
    func applyGoalUrl(_ goalUrlPattern: String) {
        kwlog.debug("received goal url pattern: \(goalUrlPattern)")
        
        self.model.goalUrl = goalUrlPattern
        
        self.dismissOnGoalUrl = true
        
        if model.goalUrl!.hasPrefix("OK") {
            model.goalUrl = model.goalUrl!.substring(from: model.goalUrl!.index(model.goalUrl!.startIndex, offsetBy: 2))
            self.dismissOnGoalUrl = false
        }
        
        self.goalUrlCondition = true;
        if model.goalUrl!.hasPrefix("!") {
            model.goalUrl = model.goalUrl!.substring(from: model.goalUrl!.index(after: model.goalUrl!.startIndex))
            self.goalUrlCondition = false
        }
        
        kwlog.debug("goal url: \(self.model.goalUrl), dismissOnGoalUrl: \(self.dismissOnGoalUrl), goalUrlCondition: \(self.goalUrlCondition)")
    }
}
