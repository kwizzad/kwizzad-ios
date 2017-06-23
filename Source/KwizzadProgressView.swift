//
//  KwizzadProgressView.swift
//  KwizzadSDK
//
//  Created by Fares Ben Hamouda on 23/02/2017.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import UIKit

open class KwizzadProgressView {
    
    var containerView = UIView()
    var progressView = UIView()
    var activityIndicator = UIActivityIndicatorView()
    
    open class var shared: KwizzadProgressView {
        struct Static {
            static let instance: KwizzadProgressView = KwizzadProgressView()
        }
        return Static.instance
    }
    
    
    open func showProgressView(_ view: UIView) {
        containerView.frame = view.frame
        containerView.center = view.center
        containerView.backgroundColor = UIColor(hex: 0xffffff, alpha: 0.3)
        
        progressView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        progressView.center = view.center
        progressView.backgroundColor = UIColor(hex: 0x444444, alpha: 0.7)
        progressView.clipsToBounds = true
        progressView.layer.cornerRadius = 10
        
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
        
        progressView.addSubview(activityIndicator)
        containerView.addSubview(progressView)
        view.addSubview(containerView)
        
        activityIndicator.startAnimating()
        
        let tapOnView = UITapGestureRecognizer(target: self, action: #selector(self.hideProgressView))
        view.addGestureRecognizer(tapOnView)
    }
    
    @objc open func hideProgressView() {
        activityIndicator.stopAnimating()
        containerView.removeFromSuperview()
    }

}

extension UIColor {
    
    convenience init(hex: UInt32, alpha: CGFloat) {
        let red = CGFloat((hex & 0xFF0000) >> 16)/256.0
        let green = CGFloat((hex & 0xFF00) >> 8)/256.0
        let blue = CGFloat(hex & 0xFF)/256.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
