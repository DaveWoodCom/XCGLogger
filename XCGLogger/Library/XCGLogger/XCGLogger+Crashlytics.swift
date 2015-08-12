//
//  XCGLogger+Crashlytics.swift
//  XCGLogger
//
//  Created by Michael Sanders on 8/12/15.
//  Copyright 2015 Cerebral Gardens. All rights reserved.
//

import Foundation

// MARK: - XCGCrashlyticsLogDestination
// - An optional log destination that sends the logs to Crashlytics
public class XCGCrashlyticsLogDestination: XCGBaseLogDestination {
    public override init(owner: XCGLogger, identifier: String) {
        super.init(owner: owner, identifier: identifier)
        showDate = false
    }

    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

    public override func output(logDetails: XCGLogDetails, text: String) {
        let adjustedText: String
        if let xcodeColor = (xcodeColors ?? owner.xcodeColors)[logDetails.logLevel] where owner.xcodeColorsEnabled {
            adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
        } else {
            adjustedText = text
        }

        let args: [CVarArgType] = [adjustedText]
        withVaList(args) { (argp: CVaListPointer) -> Void in
            #if TEST
                println(adjustedText)
            #elseif DEBUG
                CLSNSLogv("%@", argp)
            #else
                CLSLogv("%@", argp)
            #endif
        }
    }
}
