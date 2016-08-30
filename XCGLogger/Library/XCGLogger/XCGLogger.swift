//
//  XCGLogger.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation
#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

// MARK: - XCGLogDetails
/// Data structure to hold all info about a log message, passed to log destination classes
public struct XCGLogDetails {

    /// Log level required to display this log
    public var logLevel: XCGLogger.LogLevel

    /// Date this log was sent
    public var date: Date

    /// The log message to display
    public var logMessage: String

    /// Name of the function that generated this log
    public var functionName: String

    /// Name of the file the function exists in
    public var fileName: String

    /// The line number that generated this log
    public var lineNumber: Int

    public init(logLevel: XCGLogger.LogLevel, date: Date, logMessage: String, functionName: StaticString, fileName: StaticString, lineNumber: Int) {
        self.logLevel = logLevel
        self.date = date
        self.logMessage = logMessage
        self.functionName = functionName.description
        self.fileName = fileName.description
        self.lineNumber = lineNumber
    }
}

// MARK: - XCGLogDestinationProtocol
/// Protocol for log destination classes to conform to
public protocol XCGLogDestinationProtocol: CustomDebugStringConvertible {
    /// Logger that owns the log destination object
    var owner: XCGLogger {get set}

    /// Identifier for the log destination (should be unique)
    var identifier: String {get set}

    /// Log level for this destination
    var outputLogLevel: XCGLogger.LogLevel {get set}

    /// Process the log details.
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    func process(logDetails: XCGLogDetails)

    /// Process the log details (internal use, same as processLogDetails but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    func processInternal(logDetails: XCGLogDetails)

    /// Check if the log destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - logLevel: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    ///
    func isEnabledFor(logLevel: XCGLogger.LogLevel) -> Bool
}

// MARK: - XCGBaseLogDestination
/// A base class log destination that doesn't actually output the log anywhere and is intented to be subclassed
open class XCGBaseLogDestination: XCGLogDestinationProtocol, CustomDebugStringConvertible {
    // MARK: - Properties
    /// Logger that owns the log destination object
    open var owner: XCGLogger

    /// Identifier for the log destination (should be unique)
    open var identifier: String

    /// Log level for this destination
    open var outputLogLevel: XCGLogger.LogLevel = .debug

    /// Option: whether or not to output the log identifier
    open var showLogIdentifier: Bool = false

    /// Option: whether or not to output the function name that generated the log
    open var showFunctionName: Bool = true

    /// Option: whether or not to output the thread's name the log was created on
    open var showThreadName: Bool = false

    /// Option: whether or not to output the filename that generated the log
    open var showFileName: Bool = true

    /// Option: whether or not to output the line number where the log was generated
    open var showLineNumber: Bool = true

    /// Option: whether or not to output the log level of the log
    open var showLogLevel: Bool = true

    /// Option: whether or not to output the date the log was created
    open var showDate: Bool = true

    // MARK: - CustomDebugStringConvertible
    open var debugDescription: String {
        get {
            return "\(extractClassName(self)): \(identifier) - LogLevel: \(outputLogLevel) showLogIdentifier: \(showLogIdentifier) showFunctionName: \(showFunctionName) showThreadName: \(showThreadName) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber) showDate: \(showDate)"
        }
    }

    // MARK: - Life Cycle
    public init(owner: XCGLogger, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier
    }

    // MARK: - Methods to Process Log Details
    /// Process the log details.
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    open func process(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""

        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.string(from: logDetails.date)
            }

            // extendedDetails += "\(formattedDate) " // Note: Leaks in Swift versions prior to Swift 3
            extendedDetails += formattedDate + " "
        }

        if showLogLevel {
            extendedDetails += "[\(logDetails.logLevel)] "
        }

        if showLogIdentifier {
            // extendedDetails += "[\(owner.identifier)] " // Note: Leaks in Swift versions prior to Swift 3
            extendedDetails += "[" + owner.identifier + "] "
        }

        if showThreadName {
            if Thread.isMainThread {
                extendedDetails += "[main] "
            }
            else {
                if let threadName = Thread.current.name, !threadName.isEmpty {
                    extendedDetails += "[" + threadName + "] "
                }
                else if let queueName = DispatchQueue.currentQueueLabel, !queueName.isEmpty {
                    extendedDetails += "[" + queueName + "] "
                }
                else {
                    extendedDetails += "[" + String(format: "%p", Thread.current) + "] "
                }
            }
        }

        if showFileName {
            extendedDetails += "[" + (logDetails.fileName as NSString).lastPathComponent + (showLineNumber ? ":" + String(logDetails.lineNumber) : "") + "] "
        }
        else if showLineNumber {
            extendedDetails += "[" + String(logDetails.lineNumber) + "] "
        }

        if showFunctionName {
            // extendedDetails += "\(logDetails.functionName) " // Note: Leaks in Swift versions prior to Swift 3
            extendedDetails += logDetails.functionName + " "
        }

        // output(logDetails, logMessage: "\(extendedDetails)> \(logDetails.logMessage)") // Note: Leaks in Swift versions prior to Swift 3
        output(logDetails: logDetails, logMessage: extendedDetails + "> " + logDetails.logMessage)
    }

    /// Process the log details (internal use, same as process(logDetails:) but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    open func processInternal(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""

        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.string(from: logDetails.date)
            }

            // extendedDetails += "\(formattedDate) " // Note: Leaks in Swift versions prior to Swift 3
            extendedDetails += formattedDate + " "
        }

        if showLogLevel {
            extendedDetails += "[\(logDetails.logLevel)] "
        }

        if showLogIdentifier {
            // extendedDetails += "[\(owner.identifier)] " // Note: Leaks in Swift versions prior to Swift 3
            extendedDetails += "[" + owner.identifier + "] "
        }

        // output(logDetails, logMessage: "\(extendedDetails)> \(logDetails.logMessage)") // Note: Leaks in Swift versions prior to Swift 3
        output(logDetails: logDetails, logMessage: extendedDetails + "> " + logDetails.logMessage)
    }

    // MARK: - Misc methods
    /// Check if the log destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - logLevel: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    ///
    open func isEnabledFor(logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    // MARK: - Methods that must be overriden in subclasses
    /// Output the log to the destination.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - logMessage:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open func output(logDetails: XCGLogDetails, logMessage: String) {
        // Do something with the text in an overridden version of this method
        precondition(false, "Must override this")
    }
}

// MARK: - XCGConsoleLogDestination
/// A standard log destination that outputs log details to the console
open class XCGConsoleLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil

    /// The colour to use for each of the various log levels
    open var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

    // MARK: - Overridden Methods
    /// Print the log to the console.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - logMessage:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: XCGLogDetails, logMessage: String) {

        let outputClosure = {
            let adjustedLogMessage: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.logLevel], self.owner.xcodeColorsEnabled {
                adjustedLogMessage = "\(xcodeColor.format())\(logMessage)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedLogMessage = logMessage
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

// MARK: - XCGNSLogDestination
/// A standard log destination that outputs log details to the console using NSLog instead of println
open class XCGNSLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil

    /// The colour to use for each of the various log levels
    open var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

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
    ///     - logMessage:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: XCGLogDetails, logMessage: String) {

        let outputClosure = {
            let adjustedLogMessage: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.logLevel], self.owner.xcodeColorsEnabled {
                adjustedLogMessage = "\(xcodeColor.format())\(logMessage)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedLogMessage = logMessage
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

// MARK: - XCGFileLogDestination
/// A standard log destination that outputs log details to a file
open class XCGFileLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil

    /// FileURL of the file to log to
    open var writeToFileURL: URL? = nil {
        didSet {
            openFile()
        }
    }

    /// File handle for the log file
    fileprivate var logFileHandle: FileHandle? = nil

    /// Option: whether or not to append to the log file if it already exists
    fileprivate var shouldAppend: Bool

    /// Option: if appending to the log file, the string to output at the start to mark where the append took place
    fileprivate var appendMarker: String?

    // MARK: - Life Cycle
    public init(owner: XCGLogger, writeToFile: Any, identifier: String = "", shouldAppend: Bool = false, appendMarker: String? = "-- ** ** ** --") {
        self.shouldAppend = shouldAppend
        self.appendMarker = appendMarker

        super.init(owner: owner, identifier: identifier)

        if writeToFile is NSString {
            writeToFileURL = URL(fileURLWithPath: writeToFile as! String)
        }
        else if writeToFile is URL {
            writeToFileURL = writeToFile as? URL
        }
        else {
            writeToFileURL = nil
        }

        openFile()
    }

    deinit {
        // close file stream if open
        closeFile()
    }

    // MARK: - File Handling Methods
    /// Open the log file for writing.
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    fileprivate func openFile() {
        if logFileHandle != nil {
            closeFile()
        }

        if let writeToFileURL = writeToFileURL {

            let fileManager: FileManager = FileManager.default
            let fileExists: Bool = fileManager.fileExists(atPath: writeToFileURL.path)
            if !shouldAppend || !fileExists {
                fileManager.createFile(atPath: writeToFileURL.path, contents: nil, attributes: nil)
            }

            do {
                logFileHandle = try FileHandle(forWritingTo: writeToFileURL)
                if fileExists && shouldAppend {
                    logFileHandle?.seekToEndOfFile()

                    if let appendMarker = appendMarker,
                      let encodedData = "\(appendMarker)\n".data(using: String.Encoding.utf8) {
                        self.logFileHandle?.write(encodedData)
                    }
                }
            }
            catch let error as NSError {
                owner._logln("Attempt to open log file for \(fileExists && shouldAppend ? "appending" : "writing") failed: \(error.localizedDescription)", logLevel: .error)
                logFileHandle = nil
                return
            }

            let logDetails = XCGLogDetails(logLevel: .info, date: Date(), logMessage: "XCGLogger " + (fileExists && shouldAppend ? "appending" : "writing") + " log to: " + writeToFileURL.absoluteString, functionName: "", fileName: "", lineNumber: 0)
            owner._logln(logDetails.logMessage, logLevel: logDetails.logLevel)
            if owner.logDestination(withIdentifier: identifier) == nil {
                processInternal(logDetails: logDetails)
            }
        }
    }

    /// Close the log file.
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    fileprivate func closeFile() {
        logFileHandle?.closeFile()
        logFileHandle = nil
    }

    /// Rotate the log file, storing the existing log file in the specified location.
    ///
    /// - Parameters:
    ///     - archiveToFile:    FileURL or path (as String) to where the existing log file should be rotated to.
    ///
    /// - Returns:
    ///     - true:     Log file rotated successfully.
    ///     - false:    Error rotating the log file.
    ///
    @discardableResult open func rotateFile(to archiveToFile: Any) -> Bool {
        var archiveToFileURL: URL? = nil

        if archiveToFile is NSString {
            archiveToFileURL = URL(fileURLWithPath: archiveToFile as! String)
        }
        else if archiveToFile is URL {
            archiveToFileURL = archiveToFile as? URL
        }
        else {
            return false
        }

        if let archiveToFileURL = archiveToFileURL,
          let writeToFileURL = writeToFileURL {

            let fileManager: FileManager = FileManager.default
            guard !fileManager.fileExists(atPath: archiveToFileURL.path) else { return false }

            closeFile()

            do {
                try fileManager.moveItem(atPath: writeToFileURL.path, toPath: archiveToFileURL.path)
            }
            catch let error as NSError {
                openFile()
                owner._logln("Unable to rotate file \(writeToFileURL.path) to \(archiveToFileURL.path): \(error.localizedDescription)", logLevel: .error)
                return false
            }

            owner._logln("Rotated file \(writeToFileURL.path) to \(archiveToFileURL.path)", logLevel: .info)
            openFile()
            return true
        }

        return false
    }

    // MARK: - Overridden Methods
    /// Write the log to the log file.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - logMessage:         Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: XCGLogDetails, logMessage: String) {

        let outputClosure = {
            if let encodedData = "\(logMessage)\n".data(using: String.Encoding.utf8) {
                self.logFileHandle?.write(encodedData)
            }
        }

        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }
}

// MARK: - XCGLogger
/// The main logging class
open class XCGLogger: CustomDebugStringConvertible {
    // MARK: - Constants
    public struct Constants {
        /// Identifier for the default instance of XCGLogger
        public static let defaultInstanceIdentifier = "com.cerebralgardens.xcglogger.defaultInstance"

        /// Identifer for the Xcode console log destination
        public static let baseConsoleLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console"

        /// Identifier for the Apple System Log destination
        public static let nslogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console.nslog"

        /// Identifier for the file logging destination
        public static let baseFileLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.file"

        /// Identifier for the default dispatch queue
        public static let logQueueIdentifier = "com.cerebralgardens.xcglogger.queue"

        /// Library version number
        public static let versionString = "4.0.0-beta.1"
    }
    public typealias constants = Constants // Preserve backwards compatibility: Constants should be capitalized since it's a type

    // MARK: - Enums
    /// Enum defining our log levels
    public enum LogLevel: Int, Comparable, CustomStringConvertible {
        case verbose
        case debug
        case info
        case warning
        case error
        case severe
        case none

        public var description: String {
            switch self {
            case .verbose:
                return "Verbose"
            case .debug:
                return "Debug"
            case .info:
                return "Info"
            case .warning:
                return "Warning"
            case .error:
                return "Error"
            case .severe:
                return "Severe"
            case .none:
                return "None"
            }
        }
    }

    /// Structure to manage log colours
    public struct XcodeColor {

        /// ANSI code Escape sequence
        public static let escape = "\u{001b}["

        /// ANSI code to reset the foreground colour
        public static let resetFg = "\u{001b}[fg;"

        /// ANSI code to reset the background colour
        public static let resetBg = "\u{001b}[bg;"

        /// ANSI code to reset the foreground and background colours
        public static let reset = "\u{001b}[;"

        /// Tuple to store the foreground RGB colour values
        public var fg: (r: Int, g: Int, b: Int)? = nil

        /// Tuple to store the background RGB colour values
        public var bg: (r: Int, g: Int, b: Int)? = nil

        /// Generate the complete ANSI code required to set the colours specified in the object.
        ///
        /// - Parameters:
        ///     - None
        ///
        /// - Returns:  The complete ANSI code needed to set the text colours
        ///
        public func format() -> String {
            guard fg != nil || bg != nil else {
                // neither set, return reset value
                return XcodeColor.reset
            }

            var format: String = ""

            if let fg = fg {
                format += "\(XcodeColor.escape)fg\(fg.r),\(fg.g),\(fg.b);"
            }
            else {
                format += XcodeColor.resetFg
            }

            if let bg = bg {
                format += "\(XcodeColor.escape)bg\(bg.r),\(bg.g),\(bg.b);"
            }
            else {
                format += XcodeColor.resetBg
            }

            return format
        }

        public init(fg: (r: Int, g: Int, b: Int)? = nil, bg: (r: Int, g: Int, b: Int)? = nil) {
            self.fg = fg
            self.bg = bg
        }

#if os(OSX)
        public init(fg: NSColor, bg: NSColor? = nil) {
            if let fgColorSpaceCorrected = fg.usingColorSpaceName(NSCalibratedRGBColorSpace) {
                self.fg = (Int(fgColorSpaceCorrected.redComponent * 255), Int(fgColorSpaceCorrected.greenComponent * 255), Int(fgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.fg = nil
            }

            if let bg = bg,
                let bgColorSpaceCorrected = bg.usingColorSpaceName(NSCalibratedRGBColorSpace) {

                    self.bg = (Int(bgColorSpaceCorrected.redComponent * 255), Int(bgColorSpaceCorrected.greenComponent * 255), Int(bgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.bg = nil
            }
        }
#elseif os(iOS) || os(tvOS) || os(watchOS)
        public init(fg: UIColor, bg: UIColor? = nil) {
            var redComponent: CGFloat = 0
            var greenComponent: CGFloat = 0
            var blueComponent: CGFloat = 0
            var alphaComponent: CGFloat = 0

            fg.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)
            self.fg = (Int(redComponent * 255), Int(greenComponent * 255), Int(blueComponent * 255))
            if let bg = bg {
                bg.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)
                self.bg = (Int(redComponent * 255), Int(greenComponent * 255), Int(blueComponent * 255))
            }
            else {
                self.bg = nil
            }
        }
#endif

        /// XcodeColor preset foreground colour: Red
        public static let red: XcodeColor = {
            return XcodeColor(fg: (255, 0, 0))
        }()

        /// XcodeColor preset foreground colour: Green
        public static let green: XcodeColor = {
            return XcodeColor(fg: (0, 255, 0))
        }()

        /// XcodeColor preset foreground colour: Blue
        public static let blue: XcodeColor = {
            return XcodeColor(fg: (0, 0, 255))
        }()

        /// XcodeColor preset foreground colour: Black
        public static let black: XcodeColor = {
            return XcodeColor(fg: (0, 0, 0))
        }()

        /// XcodeColor preset foreground colour: White
        public static let white: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255))
        }()

        /// XcodeColor preset foreground colour: Light Grey
        public static let lightGrey: XcodeColor = {
            return XcodeColor(fg: (211, 211, 211))
        }()

        /// XcodeColor preset foreground colour: Dark Grey
        public static let darkGrey: XcodeColor = {
            return XcodeColor(fg: (169, 169, 169))
        }()

        /// XcodeColor preset foreground colour: Orange
        public static let orange: XcodeColor = {
            return XcodeColor(fg: (255, 165, 0))
        }()

        /// XcodeColor preset colours: White foreground, Red background
        public static let whiteOnRed: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0))
        }()

        /// XcodeColor preset foreground colour: Dark Green
        public static let darkGreen: XcodeColor = {
            return XcodeColor(fg: (0, 128, 0))
        }()
    }

    // MARK: - Default instance
    /// The default XCGLogger object
    open static var `default`: XCGLogger = {
        struct Statics {
            static let instance: XCGLogger = XCGLogger(identifier: XCGLogger.Constants.defaultInstanceIdentifier)
        }

        return Statics.instance
    }()

    // MARK: - Properties (Options)
    /// Identifier for this logger object (should be unique)
    open var identifier: String = ""

    /// The log level of this logger, any logs received at this level or higher will be output to the log destinations
    open var outputLogLevel: LogLevel = .debug {
        didSet {
            for index in 0 ..< logDestinations.count {
                logDestinations[index].outputLogLevel = outputLogLevel
            }
        }
    }

    /// Option: enable ANSI colour codes
    open var xcodeColorsEnabled: Bool = false

    /// The colours to use for each log level
    open var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor] = [
        .verbose: .lightGrey,
        .debug: .darkGrey,
        .info: .blue,
        .warning: .orange,
        .error: .red,
        .severe: .whiteOnRed
    ]

    /// Option: a closure to execute whenever a logging method is called without a log message
    open var noMessageClosure: () -> Any? = { return "" }

    // MARK: - Properties
    /// The default dispatch queue used for logging
    open class var logQueue: DispatchQueue {
        struct Statics {
            static var logQueue = DispatchQueue(label: XCGLogger.Constants.logQueueIdentifier, attributes: [])
        }

        return Statics.logQueue
    }

    /// The date formatter object to use when displaying the dates of log messages (internal storage)
    fileprivate var _dateFormatter: DateFormatter? = nil
    /// The date formatter object to use when displaying the dates of log messages
    open var dateFormatter: DateFormatter? {
        get {
            if _dateFormatter != nil {
                return _dateFormatter
            }

            let defaultDateFormatter = DateFormatter()
            defaultDateFormatter.locale = NSLocale.current
            defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            _dateFormatter = defaultDateFormatter

            return _dateFormatter
        }
        set {
            _dateFormatter = newValue
        }
    }

    /// Array containing all of the log destinations for this logger
    open var logDestinations: [XCGLogDestinationProtocol] = []

    // MARK: - Life Cycle
    public init(identifier: String = "", includeDefaultDestinations: Bool = true) {
        self.identifier = identifier

        // Check if XcodeColors is installed and enabled
        if let xcodeColors = ProcessInfo.processInfo.environment["XcodeColors"] {
            xcodeColorsEnabled = xcodeColors == "YES"
        }

        if includeDefaultDestinations {
            // Setup a standard console log destination
            add(logDestination: XCGConsoleLogDestination(owner: self, identifier: XCGLogger.Constants.baseConsoleLogDestinationIdentifier))
        }
    }

    // MARK: - Setup methods
    /// A shortcut method to configure the default logger instance.
    ///
    /// - Note: The function exists to get you up and running quickly, but it's recommended that you use the advanced usage configuration for most projects. See https://github.com/DaveWoodCom/XCGLogger/blob/master/README.md#advanced-usage-recommended
    ///
    /// - Parameters:
    ///     - logLevel: The log level of this logger, any logs received at this level or higher will be output to the log destinations. **Default:** Debug
    ///     - showLogIdentifier: Whether or not to output the log identifier. **Default:** false
    ///     - showFunctionName: Whether or not to output the function name that generated the log. **Default:** true
    ///     - showThreadName: Whether or not to output the thread's name the log was created on. **Default:** false
    ///     - showLogLevel: Whether or not to output the log level of the log. **Default:** true
    ///     - showFileNames: Whether or not to output the filename that generated the log. **Default:** true
    ///     - showLineNumbers: Whether or not to output the line number where the log was generated. **Default:** true
    ///     - showDate: Whether or not to output the date the log was created. **Default:** true
    ///     - writeToFile: FileURL or path (as String) to a file to log all messages to (this file is overwritten each time the logger is created). **Default:** nil => no log file
    ///     - fileLogLevel: An alternate log level for the file destination. **Default:** nil => use the same log level as the console destination
    ///
    /// - Returns:  Nothing
    ///
    open class func setup(logLevel: LogLevel = .debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: Any? = nil, fileLogLevel: LogLevel? = nil) {
        self.default.setup(logLevel: logLevel, showLogIdentifier: showLogIdentifier, showFunctionName: showFunctionName, showThreadName: showThreadName, showLogLevel: showLogLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, showDate: showDate, writeToFile: writeToFile)
    }

    /// A shortcut method to configure the logger.
    ///
    /// - Note: The function exists to get you up and running quickly, but it's recommended that you use the advanced usage configuration for most projects. See https://github.com/DaveWoodCom/XCGLogger/blob/master/README.md#advanced-usage-recommended
    ///
    /// - Parameters:
    ///     - logLevel: The log level of this logger, any logs received at this level or higher will be output to the log destinations. **Default:** Debug
    ///     - showLogIdentifier: Whether or not to output the log identifier. **Default:** false
    ///     - showFunctionName: Whether or not to output the function name that generated the log. **Default:** true
    ///     - showThreadName: Whether or not to output the thread's name the log was created on. **Default:** false
    ///     - showLogLevel: Whether or not to output the log level of the log. **Default:** true
    ///     - showFileNames: Whether or not to output the filename that generated the log. **Default:** true
    ///     - showLineNumbers: Whether or not to output the line number where the log was generated. **Default:** true
    ///     - showDate: Whether or not to output the date the log was created. **Default:** true
    ///     - writeToFile: FileURL or path (as String) to a file to log all messages to (this file is overwritten each time the logger is created). **Default:** nil => no log file
    ///     - fileLogLevel: An alternate log level for the file destination. **Default:** nil => use the same log level as the console destination
    ///
    /// - Returns:  Nothing
    ///
    open func setup(logLevel: LogLevel = .debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: Any? = nil, fileLogLevel: LogLevel? = nil) {
        outputLogLevel = logLevel

        if let standardConsoleLogDestination = logDestination(withIdentifier: XCGLogger.Constants.baseConsoleLogDestinationIdentifier) as? XCGConsoleLogDestination {
            standardConsoleLogDestination.showLogIdentifier = showLogIdentifier
            standardConsoleLogDestination.showFunctionName = showFunctionName
            standardConsoleLogDestination.showThreadName = showThreadName
            standardConsoleLogDestination.showLogLevel = showLogLevel
            standardConsoleLogDestination.showFileName = showFileNames
            standardConsoleLogDestination.showLineNumber = showLineNumbers
            standardConsoleLogDestination.showDate = showDate
            standardConsoleLogDestination.outputLogLevel = logLevel
        }

        if let writeToFile: Any = writeToFile {
            // We've been passed a file to use for logging, set up a file logger
            let standardFileLogDestination: XCGFileLogDestination = XCGFileLogDestination(owner: self, writeToFile: writeToFile, identifier: XCGLogger.Constants.baseFileLogDestinationIdentifier)

            standardFileLogDestination.showLogIdentifier = showLogIdentifier
            standardFileLogDestination.showFunctionName = showFunctionName
            standardFileLogDestination.showThreadName = showThreadName
            standardFileLogDestination.showLogLevel = showLogLevel
            standardFileLogDestination.showFileName = showFileNames
            standardFileLogDestination.showLineNumber = showLineNumbers
            standardFileLogDestination.showDate = showDate
            standardFileLogDestination.outputLogLevel = fileLogLevel ?? logLevel

            add(logDestination: standardFileLogDestination)
        }

        logAppDetails()
    }

    // MARK: - Logging methods
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - logLevel:     Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing
    ///
    open class func logln(_ closure: @autoclosure @escaping () -> Any?, logLevel: LogLevel = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - logLevel:     Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing
    ///
    open class func logln(_ logLevel: LogLevel = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - logLevel:     Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing
    ///
    open func logln(_ closure: @autoclosure @escaping () -> Any?, logLevel: LogLevel = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - logLevel:     Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing
    ///
    open func logln(_ logLevel: LogLevel = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        var logDetails: XCGLogDetails!
        for logDestination in self.logDestinations {
            guard logDestination.isEnabledFor(logLevel: logLevel) else {
                continue
            }

            if logDetails == nil {
                guard let closureResult = closure() else {
                    break
                }

                logDetails = XCGLogDetails(logLevel: logLevel, date: Date(), logMessage: String(describing: closureResult), functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            }

            logDestination.process(logDetails: logDetails)
        }
    }

    /// Execute some code only when at the specified log level.
    ///
    /// - Parameters:
    ///     - logLevel:     Specified log level **Default:** *Debug*.
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func exec(_ logLevel: LogLevel = .debug, closure: () -> () = {}) {
        self.default.exec(logLevel, closure: closure)
    }

    /// Execute some code only when at the specified log level.
    ///
    /// - Parameters:
    ///     - logLevel:     Specified log level **Default:** *Debug*.
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func exec(_ logLevel: LogLevel = .debug, closure: () -> () = {}) {
        guard isEnabledFor(logLevel:logLevel) else {
            return
        }

        closure()
    }

    /// Generate logs to display your app's vitals (app name, version, etc) as well as XCGLogger's version and log level.
    ///
    /// - Parameters:
    ///     - logLevel:     Specified log level **Default:** *Debug*.
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func logAppDetails(selectedLogDestination: XCGLogDestinationProtocol? = nil) {
        let date = Date()

        var buildString = ""
        if let infoDictionary = Bundle.main.infoDictionary {
            if let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as? String {
                // buildString = "Version: \(CFBundleShortVersionString) " // Note: Leaks in Swift versions prior to Swift 3
                buildString = "Version: " + CFBundleShortVersionString + " "
            }
            if let CFBundleVersion = infoDictionary["CFBundleVersion"] as? String {
                // buildString += "Build: \(CFBundleVersion) " // Note: Leaks in Swift versions prior to Swift 3
                buildString += "Build: " + CFBundleVersion + " "
            }
        }

        let processInfo: ProcessInfo = ProcessInfo.processInfo
        let XCGLoggerVersionNumber = XCGLogger.Constants.versionString

        // let logDetails: Array<XCGLogDetails> = [XCGLogDetails(logLevel: .info, date: date, logMessage: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
        //     XCGLogDetails(logLevel: .info, date: date, logMessage: "XCGLogger Version: \(XCGLoggerVersionNumber) - LogLevel: \(outputLogLevel)", functionName: "", fileName: "", lineNumber: 0)] // Note: Leaks in Swift versions prior to Swift 3
        var logDetails: [XCGLogDetails] = []
        logDetails.append(XCGLogDetails(logLevel: .info, date: date, logMessage: processInfo.processName + " " + buildString + "PID: " + String(processInfo.processIdentifier), functionName: "", fileName: "", lineNumber: 0))
        logDetails.append(XCGLogDetails(logLevel: .info, date: date, logMessage: "XCGLogger Version: " + XCGLoggerVersionNumber + " - LogLevel: " + outputLogLevel.description, functionName: "", fileName: "", lineNumber: 0))

        for logDestination in (selectedLogDestination != nil ? [selectedLogDestination!] : logDestinations) {
            for logDetail in logDetails {
                guard logDestination.isEnabledFor(logLevel:.info) else {
                    continue
                }

                logDestination.processInternal(logDetails: logDetail)
            }
        }
    }

    // MARK: - Convenience logging methods
    // MARK: * Verbose
    /// Log something at the Verbose log level. This format of verbose() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Verbose log level. This format of verbose() isn't provided the object to log, instead the property *`noMessageClosure`* is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Debug
    /// Log something at the Debug log level. This format of debug() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Debug log level. This format of debug() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Info
    /// Log something at the Info log level. This format of info() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Info log level. This format of info() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Warning
    /// Log something at the Warning log level. This format of warning() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Warning log level. This format of warning() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Error
    /// Log something at the Error log level. This format of error() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Error log level. This format of error() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Severe
    /// Log something at the Severe log level. This format of severe() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Severe log level. This format of severe() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: - Exec Methods
    // MARK: * Verbose
    /// Execute some code only when at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verboseExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.LogLevel.verbose, closure: closure)
    }

    /// Execute some code only when at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func verboseExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.verbose, closure: closure)
    }

    // MARK: * Debug
    /// Execute some code only when at the Debug or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debugExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.LogLevel.debug, closure: closure)
    }

    /// Execute some code only when at the Debug or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func debugExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.debug, closure: closure)
    }

    // MARK: * Info
    /// Execute some code only when at the Info or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func infoExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.LogLevel.info, closure: closure)
    }

    /// Execute some code only when at the Info or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func infoExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.info, closure: closure)
    }

    // MARK: * Warning
    /// Execute some code only when at the Warning or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warningExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.LogLevel.warning, closure: closure)
    }

    /// Execute some code only when at the Warning or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func warningExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.warning, closure: closure)
    }

    // MARK: * Error
    /// Execute some code only when at the Error or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func errorExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.LogLevel.error, closure: closure)
    }

    /// Execute some code only when at the Error or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func errorExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.error, closure: closure)
    }

    // MARK: * Severe
    /// Execute some code only when at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severeExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.LogLevel.severe, closure: closure)
    }

    /// Execute some code only when at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func severeExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.severe, closure: closure)
    }

    // MARK: - Log destination methods
    /// Get the log destination with the specified identifier.
    ///
    /// - Parameters:
    ///     - identifier:   Identifier of the log destination to return.
    ///
    /// - Returns:  The log destination with the specified identifier, if one exists, nil otherwise.
    /// 
    open func logDestination(withIdentifier identifier: String) -> XCGLogDestinationProtocol? {
        for logDestination in logDestinations {
            if logDestination.identifier == identifier {
                return logDestination
            }
        }

        return nil
    }

    /// Add a new log destination to the logger.
    ///
    /// - Parameters:
    ///     - logDestination:   The log destination to add.
    ///
    /// - Returns:
    ///     - true:     Log destination was added successfully.
    ///     - false:    Failed to add the log destination.
    ///
    @discardableResult open func add(logDestination: XCGLogDestinationProtocol) -> Bool {
        let existingLogDestination: XCGLogDestinationProtocol? = self.logDestination(withIdentifier: logDestination.identifier)
        if existingLogDestination != nil {
            return false
        }

        logDestinations.append(logDestination)
        return true
    }

    /// Remove the log destination from the logger.
    ///
    /// - Parameters:
    ///     - logDestination:   The log destination to remove.
    ///
    /// - Returns:  Nothing
    ///
    open func remove(logDestination: XCGLogDestinationProtocol) {
        remove(logDestinationWithIdentifier: logDestination.identifier)
    }

    /// Remove the log destination with the specified identifier from the logger.
    ///
    /// - Parameters:
    ///     - identifier:   The identifier of the log destination to remove.
    ///
    /// - Returns:  Nothing
    ///
    open func remove(logDestinationWithIdentifier identifier: String) {
        logDestinations = logDestinations.filter({$0.identifier != identifier})
    }

    // MARK: - Misc methods
    /// Check if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - logLevel: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Logger is at the log level specified or lower.
    ///     - false:    Logger is at a higher log levelss.
    ///
    open func isEnabledFor(logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    // MARK: - Private methods
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - logMessage:   Message to log.
    ///     - logLevel:     Specified log level.
    ///
    /// - Returns:  Nothing
    ///
    fileprivate func _logln(_ logMessage: String, logLevel: LogLevel = .debug) {

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledFor(logLevel:logLevel)) {
                if logDetails == nil {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: Date(), logMessage: logMessage, functionName: "", fileName: "", lineNumber: 0)
                }

                logDestination.processInternal(logDetails: logDetails!)
            }
        }
    }

    // MARK: - DebugPrintable
    open var debugDescription: String {
        get {
            var description: String = "\(extractClassName(self)): \(identifier) - logDestinations: \r"
            for logDestination in logDestinations {
                description += "\t \(logDestination.debugDescription)\r"
            }

            return description
        }
    }
}

// Implement Comparable for XCGLogger.LogLevel
public func < (lhs: XCGLogger.LogLevel, rhs: XCGLogger.LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func extractClassName(_ someObject: Any) -> String {
    return (someObject is Any.Type) ? "\(someObject)" : "\(type(of: someObject))"
}

extension DispatchQueue {
    public static var currentQueueLabel: String? {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))
    }
}
