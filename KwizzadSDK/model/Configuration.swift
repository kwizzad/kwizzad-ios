//
//  Configuration.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 09.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

import Foundation

@objc(KwizzadConfiguration)
open class Configuration:NSObject {
    let apiKey : String
    let overrideServer : String?
    let overrideWeb : String?
    let debug : Bool
    
    public init(apiKey:String, overrideServer:String? = nil, overrideWeb: String? = nil, debug: Bool = false) {
        self.apiKey = apiKey;
        self.overrideServer = overrideServer;
        self.overrideWeb = overrideWeb;
        self.debug = debug;
    }
    
    fileprivate init(_ b : Builder) {
        apiKey = b._apiKey!
        overrideServer = b._overrideServer
        overrideWeb = b._overrideWeb
        debug = b._debug
    }
    
    open static func create() -> Builder {
        return Builder()
    }
    
    open class Builder {
        var _apiKey : String?
        var _overrideServer : String?
        var _overrideWeb : String?
        var _debug : Bool = false
        
        public init() {
            
        }
        
        open func apiKey(_ _apiKey: String) -> Builder {
            self._apiKey = _apiKey
            return self;
        }
        
        open func overrideServer(_ _overrideServer : String) -> Builder {
            self._overrideServer = _overrideServer
            return self
        }
        
        open func overrideWeb(_ _overrideWeb : String) -> Builder {
            self._overrideWeb = _overrideWeb
            return self
        }
        
        open func debug(_ _debug : Bool) -> Builder {
            self._debug = _debug
            return self;
        }
        
        open func build() -> Configuration {
            return Configuration(self)
        }
    }
}
