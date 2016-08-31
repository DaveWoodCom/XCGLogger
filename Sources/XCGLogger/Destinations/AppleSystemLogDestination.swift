//
//  AppleSystemLogDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation

// MARK: - AppleSystemLogDestination
/// A standard destination that outputs log details to the Apple System Log using NSLog instead of print
open class AppleSystemLogDestination: BaseDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil

    /// The colour to use for each of the various log levels
    open var xcodeColors: [XCGLogger.Level: XCGLogger.XcodeColor]? = nil

    /// Option: whether or not to output the date the log was created (Always false for this destination)
    open override var showDate: Bool {
        get {
            return false
        }
        set {
            // ignored, NSLog adds the date, so we always want showDate to be false in this subclass
        }
    }

    // MARK: - Overridden Methods
    /// Print the log to the Apple System Log facility (using NSLog).
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: LogDetails, message: String) {

        let outputClosure = {
            let adjustedLogMessage: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.level], self.owner.xcodeColorsEnabled {
                adjustedLogMessage = "\(xcodeColor.format())\(message)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedLogMessage = message
            }

            NSLog("%@", adjustedLogMessage)
        }

        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }
}
