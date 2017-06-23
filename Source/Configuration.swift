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
    var overrideServer : String? = nil
    var overrideWeb : String? = nil
    var debug : Bool = false
    
    public init(apiKey:String, overrideServer:String? = nil, overrideWeb: String? = nil,debug: Bool = false) {
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
    
    public static func create() -> Builder {
        return Builder()
    }
    
    open class Builder {
        var _apiKey : String?
        var _overrideServer : String?
        var _overrideWeb : String?
        var _debug : Bool = false
        
        public init() {
            
        }
        
        /// Returns the API key to use for Kwizzad. The API key is used to identify your app.
        /// Note: Please don't share this key.
        /// Note: If you do not know your API key, ask the Kwizzad team to provide one to you.
        open func apiKey(_ _apiKey: String) -> Builder {
            self._apiKey = _apiKey
            return self;
        }
        
        /// Allows debugging Kwizzad by connecting it to another server.
        /// - Parameter _overrideServer: Base URL of the server to use, for example
        ///   `http://qa.someserver.com/`.
        open func overrideServer(_ _overrideServer : String) -> Builder {
            self._overrideServer = _overrideServer
            return self
        }
        
        /// Override the base URL of the web server for displaying Komet,
        /// a web app that is Kwizzad can show in a web view.
        /// - Parameter _overrideServer: Base URL of the server to use, for example
        ///   `http://qa.someserver.com/api/sdk/`.
        open func overrideWeb(_ _overrideWeb : String) -> Builder {
            self._overrideWeb = _overrideWeb
            return self
        }
        
        /// Switches debug logging on and off.
        open func debug(_ _debug : Bool) -> Builder {
            self._debug = _debug
            return self;
        }
        
        open func build() -> Configuration {
            return Configuration(self)
        }
    }
}
