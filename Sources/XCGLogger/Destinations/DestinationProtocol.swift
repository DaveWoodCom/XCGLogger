//
//  DestinationProtocol.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - DestinationProtocol
/// Protocol for destination classes to conform to
public protocol DestinationProtocol: CustomDebugStringConvertible {
    /// Logger that owns the destination object
    var owner: XCGLogger? {get set}

    /// Identifier for the destination (should be unique)
    var identifier: String {get set}

    /// Log level for this destination
    var outputLevel: XCGLogger.Level {get set}

    /// Flag whether or not we've logged the app details to this destination
    var haveLoggedAppDetails: Bool { get set }

    /// Process the log details.
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    func process(logDetails: LogDetails)

    /// Process the log details (internal use, same as processLogDetails but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    func processInternal(logDetails: LogDetails)

    /// Check if the destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    ///
    func isEnabledFor(level: XCGLogger.Level) -> Bool
}
