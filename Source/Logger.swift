//
//  Logger.swift
//
//  Created by Alejandro Barros Cuetos on 03/02/15.
//  Copyright (c) 2015 Alejandro Barros Cuetos. All rights reserved.
//  Adapted by Fares Ben Hamouda for TVSMILES.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  && and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

/**
 Available Log level for Logger
 - None:    Print no message
 - Error:   Message of level Error
 - Warning: Message of level Warning
 - Success: Message of level Success
 - Info:    Message of level Info
 - Custom:  Message of level Custom
 */
enum LoggerLevels: Int {

    case None = 0
    case Error
    case Warning
    case Debug
    case Info
    case Custom
}

/**
 *  Singleton class to print custom log messages easier to read
 *  and analize. Based in glyphs and log levels
 */
class Logger {

    // MARK: - Properties

    var verbosityLevel: LoggerLevels = .Custom

    var errorGlyph: String = "\u{1F6AB}"    // Glyph for messages of level .Error
    var warningGlyph: String = "\u{1F514}"  // Glyph for messages of level .Warning
    var successGlyph: String = "\u{2705}"   // Glyph for messages of level .Success
    var infoGlyph: String = "\u{1F535}"     // Glyph for messages of level .Info
    var customGlyph: String = "\u{1F536}"   // Glyph for messages of level .Custom

    // MARK: Public methods

    /**
     Prints a formatted message through the debug console,
     showing a glyph based on the loglevel and the name of the file
     invoking it if present

     :param: message      Message to print
     :param: logLevel     Level of the log message
     :param: file         Implicit parameter, file calling the method
     :param: line         Implicit parameter, line which the call was made
     */
    func logMessage(_ message: String , _ logLevel: LoggerLevels = .Info, file: String = #file, line: UInt = #line) {
        if (KwizzadSDK.instance.showDebugMessages) {
            if self.verbosityLevel.rawValue > LoggerLevels.None.rawValue &&  logLevel.rawValue <= self.verbosityLevel.rawValue {
                print("\(getGlyphForLogLevel(logLevel: logLevel))\(message) [\(file):\(line)] \(message)")
            }
        }
    }

    /**
     Prints a formatted message through the debug console,
     showing a glyph based on the loglevel and the name of the class
     invoking it if present

     :param: message      Message to print
     :param: logLevel     Level of the log message
     :param: file         Implicit parameter, file calling the method
     :param: line         Implicit parameter, line which the call was made

     :returns: A formatted string
     */
    func getMessage(message: String, _ logLevel: LoggerLevels = .Info, file: String = #file, line: UInt = #line) -> String {

        return("\(getGlyphForLogLevel(logLevel: logLevel))\(message) [\(file):\(line)] \(message)")
    }


    // MARK: - Private Methods

    /**
     Returns the Glyph to use according to the passed LogLevel

     :param: logLevel

     :returns: A formatted string with the matching glyph
     */
    private func getGlyphForLogLevel(logLevel: LoggerLevels) -> String {

        switch logLevel
        {
        case .Error:
            return "\(errorGlyph) "
        case .Warning:
            return "\(warningGlyph) "
        case .Debug:
            return "\(successGlyph) "
        case .Info:
            return "\(infoGlyph) "
        case .Custom:
            return "\(customGlyph) "
        default:
            return " "
        }
    }

    // MARK: - Singleton Pattern

    class var sharedInstance: Logger {

        struct Singleton {
            static let instance = Logger()
        }

        return Singleton.instance
    }
}
