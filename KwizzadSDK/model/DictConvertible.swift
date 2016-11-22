//
//  OConvertible.swift
//  KwizzadSDK
//
//  Created by Sandro Manke on 19.10.16.
//  Copyright © 2016 Kwizzad. All rights reserved.
//

// why? because. thats why :)

import Foundation

public protocol ToDict {
    func toDict(_ map: inout [String : Any])
}

public protocol FromDict {
    init(_ map: [String:Any])
}

class Convertibles {
    
    static let instance = Convertibles()

    public var convertibleTypes: [String: String] = [:]
    
    init() {
    }
    
    public func add( clazz : AnyClass, type: String) {
        convertibleTypes[type] = NSStringFromClass(clazz);
    }
}

infix operator -->

func dictConvert <T : ToDict>(_ o: T?) -> String? {
    
    if let map : [String:Any] = dictConvert(o) {
        do {
            if JSONSerialization.isValidJSONObject(map), let foo = try String(data:JSONSerialization.data(withJSONObject: map, options: .prettyPrinted), encoding: .utf8) {
                return foo;
            }
            else {
                kwlog.error("not json convertible \(map)")
            }
        }
        catch {
            kwlog.error("oh no \(error)")
        }
    }
    
    return nil
}

func fromISO8601(_ str: Any?) -> Date? {
    if let rr = str as? String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let ret = f.date(from: rr) {
            return ret
        }
        
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return f.date(from: rr)
    }
    else {
        return nil
    }
}

func toISO8601(_ date: Date?) -> String? {
    if date != nil {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f.string(from: date!)
    }
    else {
        return nil
    }
}

func dictConvert <T : ToDict>(_ o: T?) -> [String: Any]? {
    guard o != nil else {
        return nil
    }
    
    var map : [String:Any] = [:]
    o!.toDict(&map)
    return map
}

func dictConvert (str: String?) -> [String: Any]? {
    guard str != nil else {
        return nil
    }
    
    if let data = str!.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        }
        catch {
        }
    }
    kwlog.debug("could not deserialize \(str)")
    return nil
}

func dictConvert (str: String?) -> NSArray? {
    guard str != nil else {
        return nil
    }
    if let data = str!.data(using: .utf8) {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSArray
        }
        catch {
        }
    }
    kwlog.debug("could not deserialize \(str)")
    return nil
}

func dictConvert <T : FromDict> (str: String?) -> T {
    return dictConvert(str: str)
}

func dictConvert (str: String?) -> FromDict? {
    guard str != nil else {
        return nil
    }
    
    if let dict : [String: Any] = dictConvert(str: str) {
        return dictConvertToObject(fromDict: dict)
    }
    
    return nil
}

func dictConvert (str: String?) -> [FromDict] {
    var ret:[FromDict] = [];
    
    if let foo:NSArray = dictConvert(str: str) {
        for entry in foo {
            if let ff = dictConvertToObject(fromDict: entry as? [String:Any]) {
                ret.append(ff)
            }
        }
    }
    
    return ret
}

func dictConvertToObject <T : FromDict>(arr: [[String : Any]]?, type: T.Type) -> [T]? {
    if let array = arr {
        var ret : [T] = []
        
        for dict in array {
            ret.append(type.init(dict))
        }
        
        return ret
    }
    
    return nil;
}

func dictConvertToObject (fromDict dict: [String : Any]?) -> FromDict? {
    guard dict != nil else {
        return nil
    }
    
    if let type = dict!["type"] as? String {
        if let clazz = Convertibles.instance.convertibleTypes[type] {
            if let clazz = NSClassFromString(clazz) as? FromDict.Type {
                return clazz.init(dict!)
            }
            else {
                kwlog.error("\(type) not FromDict")
            }
        }
        else {
            kwlog.error("\(type) was not registered");
        }
    }
    else {
        kwlog.error("no type found in \(dict)")
    }
    
    return nil;
}


func --> (x: (value: Any?, key: String)?, dict: inout [String : Any]) {
    if let value = x?.value {
        if let dd = value as? ToDict {
            var map : [String:Any] = [:]
            dd.toDict(&map)
            dict[x!.key] = map
        }
        else if let dd = value as? NSArray {
            var outarr : [Any] = []
            
            for el in dd {
                if let kk = el as? ToDict {
                    var map : [String:Any] = [:]
                    kk.toDict(&map)
                    outarr.append(map)
                }
                else {
                    outarr.append(el)
                }
            }
            
            dict[x!.key] = outarr
        }
        else {
            dict[x!.key] = value
        }
    }
}

