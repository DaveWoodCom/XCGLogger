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
            var logDetails = logDetails
            var message = message

            // Apply filters, if any indicate we should drop the message, we abort before doing the actual logging
            if self.shouldExclude(logDetails: &logDetails, message: &message) {
                return
            }

            self.applyFormatters(logDetails: &logDetails, message: &message)

            print(message)
        }

        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }
}
