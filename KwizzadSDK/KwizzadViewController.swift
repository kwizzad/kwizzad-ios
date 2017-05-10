//
//  KwizzadViewController.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 13.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation
import RxSwift
import WebKit

class KwizzadViewController : UIViewController {
    let placement : PlacementModel
    let button : UIButton
    let api : KwizzadAPI
    let customParameters: [String:Any]?;
    var viewAppeared = false;
    var goalReached = false;
    var callToActionClicked = false;

    var disposeBag = DisposeBag()
    var controller : WKController?
    var webView : WKWebView?

    var open = true

    public static func create(placement : PlacementModel, api : KwizzadAPI, customParameters: [String:Any]? = nil) -> KwizzadViewController {
        // Displays a progressView on top of the view controller
        let viewController = KwizzadViewController(placement: placement, api: api, customParameters: customParameters);

        UIApplication.shared.keyWindow?.insertSubview(viewController.view, at: 0)

        viewController.start();

        return viewController;
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

    func showProgressView() {
        KwizzadProgressView.shared.showProgressView(self.view)
    }

    fileprivate func start() {
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

        button.addTarget(self, action: #selector(KwizzadViewController.closeButtonClick), for: .touchUpInside)

        button.translatesAutoresizingMaskIntoConstraints = false

        button.contentEdgeInsets = UIEdgeInsetsMake(5,5,5,5)

        button.sizeToFit()

        view.addSubview(button)

        if #available(iOS 9.0, *) {
            button.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            button.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

        } else {
            // Fallback on earlier versions
            let constTop:NSLayoutConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0);
            self.view.addConstraint(constTop);

            let constRight:NSLayoutConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.right, multiplier: 1, constant: 0);
            self.view.addConstraint(constRight);
        }


        placement.adStateObservable.subscribe(onNext: {adState in
            logger.logMessage("kwizzadView received \(adState)")

            switch(adState) {
            case .CALL2ACTION:
                Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.showProgressView), userInfo: nil, repeats: false)
                break;
            case .CALL2ACTIONCLICKED:
                self.callToActionClicked = true;
                KwizzadSDK.instance.delegate?.kwizzadCallToActionClicked?(placementId: self.placement.placementId);
            case .GOAL_REACHED:
                self.button.setImage(UIImage(named: "okay", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .normal)
                self.button.setImage(UIImage(named: "okay_active", in: Bundle(for: type(of: self)), compatibleWith: nil), for: .highlighted)
                self.goalReached = true;
                KwizzadSDK.instance.delegate?.kwizzadOnGoalReached?(placementId: self.placement.placementId);
            case .AD_READY:
                if(self.viewAppeared) {
                    self.placement.transition(to: AdState.SHOWING_AD)
                }
                else {
                    logger.logMessage("ad ready, but view not appeared yet");
                }

                break;
            case .SHOWING_AD:
                _ = self.api.queue(AdTrackingEvent(action: "adStarted", forAd: self.placement.adResponse!.adId!).customParams(self.customParameters))
                self.webView?.isHidden = false
            case .DISMISSED:
                self.closeAd();
                self.dismiss(animated: true)
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

    override func viewWillDisappear(_ animated: Bool) {
        logger.logMessage("view will disappear")
        KwizzadSDK.instance.delegate?.kwizzadWillDismissAd?(placementId: self.placement.placementId);
        closeAd()
    }

    func dismissAndClosePlacement() {
        self.dismiss(animated: true, completion: {
            self.placement.close();
        })
    }

    func forfeitRewardsText() -> String {
        if let reward = self.placement.adResponse?.rewards?.first(where: { $0.type == "CALLBACK" }) {
            if reward.currency != nil {
                if let maxAmount = reward.maxAmount {
                    if maxAmount.intValue > 0 {
                        return KwizzadLocalized("alert_close_title_var",replacements: ["#number_of_rewards#":"\(maxAmount)", "#reward_name#":"\(reward.currency!)"])
                    }
                }
                if let amount = reward.amount {
                    if amount.intValue > 0 {
                        return KwizzadLocalized("alert_close_title",replacements: ["#number_of_rewards#":"\(amount)", "#reward_name#":"\(reward.currency!)"])
                    }
                }
            }
        }

        return KwizzadLocalized("alert_close_title_0");
    }

    func closeButtonClick() {
        logger.logMessage(self.placement.adResponse.debugDescription)

        logger.logMessage("Close button clicked")

        if (goalReached) {
            self.dismissAndClosePlacement()
            return
        }

        if (callToActionClicked && (self.placement.goalUrl == nil || self.placement.goalUrl!.isEmpty)) {
            let alert = UIAlertController(title: nil, message: KwizzadLocalized("close_alert_title"), preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: KwizzadLocalized("close_alert_no"), style: UIAlertActionStyle.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: KwizzadLocalized("close_alert_yes"), style: UIAlertActionStyle.default, handler: { foo in
                self.dismissAndClosePlacement()
            }))
            self.present(alert, animated: true, completion: nil)
        }
        else {
            let msg = self.forfeitRewardsText()
            let alert = UIAlertController(title: nil, message: msg, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: KwizzadLocalized("alert_close_claim"), style: UIAlertActionStyle.cancel, handler: { foo in
            }))
            alert.addAction(UIAlertAction(title: KwizzadLocalized("alert_close_forfeit"), style: UIAlertActionStyle.destructive, handler: { foo in
                self.dismissAndClosePlacement()
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

        logger.logMessage("closing ad")

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
        KwizzadSDK.instance.delegate?.kwizzadWillPresentAd?(placementId: placement.placementId)
        viewAppeared = true;

        logger.logMessage("view appear on state \(self.placement.adState)")

        guard placement.transition(from: AdState.AD_READY, to: AdState.SHOWING_AD) else {
            return
        }
    }
}
