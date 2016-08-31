//
//  ConsoleDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - ConsoleDestination
/// A standard destination that outputs log details to the console
open class ConsoleDestination: BaseDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil

    /// The colour to use for each of the various log levels
    open var xcodeColors: [XCGLogger.Level: XCGLogger.XcodeColor]? = nil

    // MARK: - Overridden Methods
    /// Print the log to the console.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: LogDetails, message: String) {

        let outputClosure = {
            guard let owner = self.owner else { return }

            let adjustedLogMessage: String
            if let xcodeColor = (self.xcodeColors ?? owner.xcodeColors)[logDetails.level], owner.xcodeColorsEnabled {
                adjustedLogMessage = "\(xcodeColor.format())\(message)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedLogMessage = message
            }

            print(adjustedLogMessage)
        }

        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }
}
