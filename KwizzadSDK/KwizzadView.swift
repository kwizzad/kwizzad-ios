//
//  KwizzadView.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 13.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift
import WebKit
import XCGLogger

class KwizzadView : UIViewController {
    let placement : PlacementModel
    let button : UIButton
    let api : KwizzadAPI
    let customParameters: [String:Any]?;
    var viewAppeared = false;
    var goalReached=false;
    
    var disposeBag = DisposeBag()
    var controller : WKController?
    var webView : WKWebView?
    
    var open = true
    
    public static func create(placement : PlacementModel, api : KwizzadAPI, customParameters: [String:Any]? = nil) -> KwizzadView {
        let view = KwizzadView(placement: placement, api: api, customParameters: customParameters);
        
        UIApplication.shared.keyWindow?.insertSubview(view.view, at: 0)
        
        view.startme();
        
        return view;
    }
    
    fileprivate init(placement : PlacementModel, api : KwizzadAPI, customParameters: [String:Any]? = nil) {
        self.placement = placement
        self.api = api
        self.button = UIButton(type: .custom)
        self.customParameters = customParameters;
        
        super.init(nibName: nil, bundle: nil)
        
        self.modalTransitionStyle = .coverVertical
    }
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        get {
            return .overFullScreen
        }
        set {}
    }
    
    override var modalPresentationCapturesStatusBarAppearance: Bool {
        get {
            return true
        }
        set {}
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    fileprivate func startme() {
        kwlog.debug("viewWillLayoutSubviews")
        
        
/*        if #available(iOS 9.0, *) {
            let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
            let date = Date(timeIntervalSince1970: 0)
            WKWebsiteDataStore.default().removeData(ofTypes:websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
        }
        
        URLCache.shared.removeAllCachedResponses();*/
        
        let contentController = WKUserContentController();
        
        controller = WKController(placement, api);
        
        contentController.add(
            controller!,
            name: "KwizzAdJI"
        )
        
        let conf = WKWebViewConfiguration()
        conf.allowsInlineMediaPlayback = false;
        conf.userContentController = contentController;
        
        if #available(iOS 9, *) {
            conf.allowsPictureInPictureMediaPlayback = false
            conf.requiresUserActionForMediaPlayback = false
            conf.allowsAirPlayForMediaPlayback = false
        }
        else {
            conf.mediaPlaybackRequiresUserAction = false
            conf.mediaPlaybackAllowsAirPlay = false
        }
        
        /*let webView2 = WKWebView(frame: self.view.bounds);
        webView2.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        webView2.load(URLRequest(url: URL(string:"http://www.google.de")!));
        view.addSubview(webView2);
        */
        
        let webView = WKWebView(frame: self.view.bounds, configuration: conf)
        self.webView = webView;
        self.webView?.isHidden = true
        
        self.webView!.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        
        webView.navigationDelegate = controller;
        webView.allowsBackForwardNavigationGestures = false
        webView.isMultipleTouchEnabled=false;
        
        if #available(iOS 9, *) {
            webView.allowsLinkPreview = false
        }
        
        webView.load(URLRequest(url: URL(string: placement.adResponse!.url!)!));
        
        view.addSubview(webView)
        
        button.setImage(UIImage(named: "close", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
        button.setImage(UIImage(named: "close_active", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .highlighted)
        
        button.addTarget(self, action: #selector(KwizzadView.closeButtonClick), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        
        button.contentEdgeInsets = UIEdgeInsetsMake(10,10,10,10)
        
        button.sizeToFit()
        
        view.addSubview(button)
        
        button.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        button.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        
        placement.adStateObservable.subscribe(onNext: {adState in
            
            kwlog.debug("kwizzadView received \(adState)")
            
            switch(adState) {
            case .GOAL_REACHED:
                self.button.setImage(UIImage(named: "okay", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                self.button.setImage(UIImage(named: "okay_active", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .highlighted)
                self.goalReached = true;
            case .AD_READY:

                // evil, has to go.
                /*DispatchQueue.main.async {
                    if !self.isBeingPresented {
                        self.view.removeFromSuperview()
                    }
                }*/
                
                if(self.viewAppeared) {
                    self.placement.transition(to: AdState.SHOWING_AD)
                }
                else {
                    kwlog.debug("ad ready, but view not appeared yet");
                }
                
                break;
            case .SHOWING_AD:
                _ = self.api.queue(AdTrackingEvent(action: "adStarted", forAd: self.placement.adResponse!.adId!).customParams(self.customParameters))
                self.webView?.isHidden = false
            case .DISMISSED:
                self.closeAd();
                self.dismiss(animated: true, completion: {
                    
                })
                break;
            default:
                break
            }
        }).addDisposableTo(disposeBag)
        
        button.isHidden = true
        
        placement.closeButtonVisibleObservable.subscribe(onNext: { value in
            self.button.isHidden = !value
        }).addDisposableTo(disposeBag)

    }
    
    /*override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }*/
    
    
    override func viewWillDisappear(_ animated: Bool) {
        kwlog.debug("view will disappear")
        closeAd()
    }
    
    func closeButtonClick() {
        
        kwlog.debug("close clicked")
        if(goalReached) {
            self.dismiss(animated: true, completion: {
                
            })
        }
        else {
            let msg = "Are you sure you want to quit and miss out on #number_of_rewards# #reward_name#?"
            
            let alert = UIAlertController(title: "Are you sure?", message: msg, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Continue and claim reward", style: UIAlertActionStyle.cancel, handler: { foo in
            }))
            alert.addAction(UIAlertAction(title: "Quit and forfeit reward", style: UIAlertActionStyle.destructive, handler: { foo in
                self.dismiss(animated: true)
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func closeAd()
    {
        if(!open) {
            return
        }
        open=false
        
        kwlog.debug("closing ad")
        
        disposeBag = DisposeBag()
        
        _ = api.queue(
            AdTrackingEvent(action: "adDismissed", forAd: placement.adResponse!.adId!)
            .setStep(placement.currentStep)
        )
        
        // we definitely set it to dismissed here, so not kwizzad.close
        placement.transition(to: AdState.DISMISSED)
        
        controller?.detach();
        controller = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }
    
    override func viewDidAppear(_ animated: Bool) {
        viewAppeared = true;
        
        kwlog.debug("view appear on state \(self.placement.adState)")
        
        guard placement.transition(from: AdState.AD_READY, to: AdState.SHOWING_AD) else {
            return
        }
    }
}
