//
//  XCGLogWrapper.swift
//  XCGLogger
//
//  Created by Anders Borch on 3/7/16.
//  Copyright © 2016 Cerebral Gardens. All rights reserved.
//

import Foundation

@objc public enum LogLevel: Int {
    case Verbose
    case Debug
    case Info
    case Warning
    case Error
    case Severe
    case None
}

// Obj-c wrapper for XCGLogger
public class XCGLogWrapper: NSObject {
    
    public static func log(level: LogLevel, functionName: String, fileName: String, lineNumber: Int, logMessage: String) {
        let log = XCGLogger.defaultInstance()
        let wrapped = XCGLogger.LogLevel(rawValue: level.rawValue)
        log.logln(wrapped!, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: { () -> String? in
            return logMessage
        })
    }
    
}
