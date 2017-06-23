//
//  AdView.swift
//  KwizzadExample
//
//  Created by Fares Ben Hamouda on 25.04.17.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import UIKit

@objc
@IBDesignable public class AdView: UIControl {
    
    var view: UIView?;
    let borderWidth: CGFloat = 1
    
    var _imageSize: CGFloat = 180
    var _verticalPadding: CGFloat = 15
    var _horizontalPadding: CGFloat = 20
    var _maxHeight: CGFloat = 180

    @IBInspectable public var imageSize: CGFloat = 180 {
        didSet {
            _imageSize = imageSize
            layoutSubviews()
        }
    }
    
    @IBInspectable public var verticalPadding: CGFloat = 15 {
        didSet {
            _verticalPadding = verticalPadding
            layoutSubviews()
        }
    }
    
    @IBInspectable public var horizontalPadding: CGFloat = 20 {
        didSet {
            _horizontalPadding = horizontalPadding
            layoutSubviews()
        }
    }
    
    @IBInspectable public var bgColor: UIColor = UIColor.purple {
        didSet {
            self.view?.backgroundColor = bgColor
        }
        
    }

    @IBInspectable public var maxHeight: CGFloat = 180 {
        didSet {
            _maxHeight = maxHeight
            layoutSubviews()
        }
    }
    
    @IBOutlet public var smilesLabel: UILabel!
    @IBOutlet public var imageView: UIImageView!
    @IBOutlet public var headlineLabel: UILabel!
    @IBOutlet public var detailsLabel: UILabel!

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        self.view = UINib(nibName: "AdView", bundle: Bundle(for: type(of: self))).instantiate(withOwner: self, options: nil)[0] as? UIView
        self.addSubview(self.view!)
    }
    
    // Add rounded corners and border
    func roundedCorners(view : UIView?, withBorder : Bool, cornerRadius: CGFloat) {
        view?.layer.cornerRadius = cornerRadius
        if withBorder {
            view?.layer.borderColor = UIColor.init(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.1).cgColor
            view?.layer.borderWidth = 1.0
        }
        view?.layer.masksToBounds = true
        view?.clipsToBounds = true
    }
    
    override public func draw(_ rect:  CGRect) {
        // roundedCorners(view: self.view, withBorder: true, cornerRadius: 18)
        // roundedCorners(view: self.smilesLabel, withBorder: false, cornerRadius: self.smilesLabel.bounds.height / 2)
        roundedCorners(view: self.smilesLabel, withBorder: false, cornerRadius: 3.0)
        roundedCorners(view: self.view, withBorder: true, cornerRadius: 6.0)
    }
    
    override public func layoutSubviews() {
        self.view?.frame = CGRect.init(origin: CGPoint.zero, size: self.frame.size)
        self.imageView.frame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: _imageSize, height: _imageSize))
        let labelWidth = self.frame.width - _imageSize - 2 * _horizontalPadding
        let labelLeft = _imageSize + _horizontalPadding
        self.headlineLabel.frame = CGRect.init(origin: CGPoint.init(x: labelLeft, y: _verticalPadding), size: CGSize.init(width: labelWidth, height: 20));
        self.headlineLabel.preferredMaxLayoutWidth = labelWidth
        self.headlineLabel.sizeToFit()
        self.detailsLabel.frame = CGRect.init(origin: CGPoint.init(x: labelLeft, y: headlineLabel.frame.origin.y + headlineLabel.frame.height + _verticalPadding), size: CGSize.init(width: labelWidth, height: 20))
        self.detailsLabel.preferredMaxLayoutWidth = labelWidth;
        self.detailsLabel.sizeToFit()
        self.smilesLabel.sizeToFit()
        
        let smilesLabelBounds = self.smilesLabel.bounds.insetBy(dx: -8, dy: -3)
        self.smilesLabel.frame = smilesLabelBounds.offsetBy(dx: self.frame.width - smilesLabelBounds.width, dy: 12)
    }
    
    public func preferredHeight() -> CGFloat {
        return min(_maxHeight, max(imageSize, self.headlineLabel.frame.height + self.detailsLabel.frame.height + verticalPadding * 3));
    }
}
