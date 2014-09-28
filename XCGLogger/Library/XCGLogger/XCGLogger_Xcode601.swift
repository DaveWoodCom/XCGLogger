//
//  XCGLogger_Xcode601.swift
//  XCGLogger
//
//  Created by Dave Wood on 2014-09-27.
//  Copyright (c) 2014 Cerebral Gardens. All rights reserved.
//

// Note: If using XCGLogger in Xcode 6.0.1, which uses Swift 1.0, ensure this
// file is included in the three targets: XCGLogger (iOS), XCGLogger (OS X), and
// XCGLoggerTests. This includes some code to make XCGLogger backwards
// compatible with Swift 1.0.

import Foundation

public extension XCGLogger.LogLevel {
    public var rawValue: Int {
        return self.toRaw()
    }
}

public extension NSFileHandle {
    convenience init(forWritingToURL url: NSURL, error: NSErrorPointer) {
        self.init()
        NSFileHandle.fileHandleForWritingToURL(url, error: error)
    }
}

