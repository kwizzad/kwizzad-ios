//
//  ImageInfo.swift
//  KwizzadSDK
//
//  Created by Sebastian Felix Zappe on 06/04/2017.
//  Copyright © 2017 Kwizzad. All rights reserved.
//

import Foundation

/// Represents an image resource that can be loaded in different resolutions over the web.
@objc(KwizzadImageInfo)
open class ImageInfo : NSObject, FromDict {
    /// Semantic type of the referenced image, e.g. `"thumbnail"` or `"banner"`
    public let type : String?
    
    /// URL of the image in an arbitrary resolution
    public let url : String?
    
    /// Template string for URLs to load the image in a specified resolution.
    /// This string can contain `"{{width}}" and `"{{height}}"`. By replacing occurences
    /// of these substrings with valid pixel heights, you can generate your own URL for
    /// an image in a size you specify.
    public let urlTemplate : String?
    
    /// Original width of the image. Helpful to derive the aspect ratio.
    public let width : NSNumber?

    /// Original height of the image. Helpful to derive the aspect ratio.
    public let height : NSNumber?
    
    /// - returns: A URL string for the image resource in a given width and height, in pixels.
    public func url(_ width:Int = 0, height:Int = 0) -> String? {
        guard let urlTemplate = self.urlTemplate else { return self.url; }
        
        return urlTemplate
            .replacingOccurrences(of: "{{width}}", with: String(width))
            .replacingOccurrences(of: "{{height}}", with: String(height));
    }
    
    public required init(_ map: [String : Any]) {
        type = map["type"] as? String
        url = map["url"] as? String
        urlTemplate = map["urlTemplate"] as? String
        width = map["width"] as? NSNumber
        height = map["height"] as? NSNumber
    }
}
