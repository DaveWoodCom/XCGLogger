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
    public var date: NSDate

    /// The log message to display
    public var logMessage: String

    /// Name of the function that generated this log
    public var functionName: String

    /// Name of the file the function exists in
    public var fileName: String

    /// The line number that generated this log
    public var lineNumber: Int

    public init(logLevel: XCGLogger.LogLevel, date: NSDate, logMessage: String, functionName: String, fileName: String, lineNumber: Int) {
        self.logLevel = logLevel
        self.date = date
        self.logMessage = logMessage
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
    }
}

// MARK: - XCGLogDestinationProtocol
/// Protocol for output classes to conform to
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
    func processLogDetails(logDetails: XCGLogDetails)

    /// Process the log details (internal use, same as processLogDetails but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    func processInternalLogDetails(logDetails: XCGLogDetails)

    /// Check if the log destination's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - logLevel: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Log destination is at the log level specified or lower.
    ///     - false:    Log destination is at a higher log level.
    ///
    func isEnabledForLogLevel(logLevel: XCGLogger.LogLevel) -> Bool
}

// MARK: - XCGBaseLogDestination
/// A base class log destination that doesn't actually output the log anywhere and is intented to be subclassed
public class XCGBaseLogDestination: XCGLogDestinationProtocol, CustomDebugStringConvertible {
    // MARK: - Properties
    /// Logger that owns the log destination object
    public var owner: XCGLogger

    /// Identifier for the log destination (should be unique)
    public var identifier: String

    /// Log level for this destination
    public var outputLogLevel: XCGLogger.LogLevel = .Debug

    /// Option: whether or not to output the log identifier
    public var showLogIdentifier: Bool = false

    /// Option: whether or not to output the function name that generated the log
    public var showFunctionName: Bool = true

    /// Option: whether or not to output the thread's name the log was created on
    public var showThreadName: Bool = false

    /// Option: whether or not to output the filename that generated the log
    public var showFileName: Bool = true

    /// Option: whether or not to output the line number where the log was generated
    public var showLineNumber: Bool = true

    /// Option: whether or not to output the log level of the log
    public var showLogLevel: Bool = true

    /// Option: whether or not to output the date the log was created
    public var showDate: Bool = true

    // MARK: - CustomDebugStringConvertible
    public var debugDescription: String {
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
    public func processLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""

        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.stringFromDate(logDetails.date)
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
            if NSThread.isMainThread() {
                extendedDetails += "[main] "
            }
            else {
                if let threadName = NSThread.currentThread().name where !threadName.isEmpty {
                    extendedDetails += "[" + threadName + "] "
                }
                else if let queueName = String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) where !queueName.isEmpty {
                    extendedDetails += "[" + queueName + "] "
                }
                else {
                    extendedDetails += "[" + String(format: "%p", NSThread.currentThread()) + "] "
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

        // output(logDetails, text: "\(extendedDetails)> \(logDetails.logMessage)") // Note: Leaks in Swift versions prior to Swift 3
        output(logDetails, text: extendedDetails + "> " + logDetails.logMessage)
    }

    /// Process the log details (internal use, same as processLogDetails but omits function/file/line info).
    ///
    /// - Parameters:
    ///     - logDetails:   Structure with all of the details for the log to process.
    ///
    /// - Returns:  Nothing
    ///
    public func processInternalLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""

        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.stringFromDate(logDetails.date)
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

        // output(logDetails, text: "\(extendedDetails)> \(logDetails.logMessage)") // Note: Leaks in Swift versions prior to Swift 3
        output(logDetails, text: extendedDetails + "> " + logDetails.logMessage)
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
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    // MARK: - Methods that must be overriden in subclasses
    /// Output the log to the destination.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - text:         Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    public func output(logDetails: XCGLogDetails, text: String) {
        // Do something with the text in an overridden version of this method
        precondition(false, "Must override this")
    }
}

// MARK: - XCGConsoleLogDestination
/// A standard log destination that outputs log details to the console
public class XCGConsoleLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    public var logQueue: dispatch_queue_t? = nil

    /// The colour to use for each of the various log levels
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

    // MARK: - Overridden Methods
    /// Print the log to the console.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - text:         Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    public override func output(logDetails: XCGLogDetails, text: String) {

        let outputClosure = {
            let adjustedText: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.logLevel] where self.owner.xcodeColorsEnabled {
                adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedText = text
            }

            print(adjustedText)
        }

        if let logQueue = logQueue {
            dispatch_async(logQueue, outputClosure)
        }
        else {
            outputClosure()
        }
    }
}

// MARK: - XCGNSLogDestination
/// A standard log destination that outputs log details to the console using NSLog instead of println
public class XCGNSLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    public var logQueue: dispatch_queue_t? = nil

    /// The colour to use for each of the various log levels
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil

    /// Option: whether or not to output the date the log was created (Always false for this destination)
    public override var showDate: Bool {
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
    ///     - text:         Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    public override func output(logDetails: XCGLogDetails, text: String) {

        let outputClosure = {
            let adjustedText: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.logLevel] where self.owner.xcodeColorsEnabled {
                adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedText = text
            }

            NSLog("%@", adjustedText)
        }

        if let logQueue = logQueue {
            dispatch_async(logQueue, outputClosure)
        }
        else {
            outputClosure()
        }
    }
}

// MARK: - XCGFileLogDestination
/// A standard log destination that outputs log details to a file
public class XCGFileLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    public var logQueue: dispatch_queue_t? = nil

    /// FileURL of the file to log to
    public var writeToFileURL: NSURL? = nil {
        didSet {
            openFile()
        }
    }

    /// File handle for the log file
    private var logFileHandle: NSFileHandle? = nil

    /// Option: whether or not to append to the log file if it already exists
    private var shouldAppend: Bool

    /// Option: if appending to the log file, the string to output at the start to mark where the append took place
    private var appendMarker: String?

    // MARK: - Life Cycle
    public init(owner: XCGLogger, writeToFile: AnyObject, identifier: String = "", shouldAppend: Bool = false, appendMarker: String? = "-- ** ** ** --") {
        self.shouldAppend = shouldAppend
        self.appendMarker = appendMarker

        super.init(owner: owner, identifier: identifier)

        if writeToFile is NSString {
            writeToFileURL = NSURL.fileURLWithPath(writeToFile as! String)
        }
        else if writeToFile is NSURL {
            writeToFileURL = writeToFile as? NSURL
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
    private func openFile() {
        if logFileHandle != nil {
            closeFile()
        }

        if let writeToFileURL = writeToFileURL,
          let path = writeToFileURL.path {

            let fileManager: NSFileManager = NSFileManager.defaultManager()
            let fileExists: Bool = fileManager.fileExistsAtPath(path)
            if !shouldAppend || !fileExists {
                fileManager.createFileAtPath(path, contents: nil, attributes: nil)
            }

            do {
                logFileHandle = try NSFileHandle(forWritingToURL: writeToFileURL)
                if fileExists && shouldAppend {
                    logFileHandle?.seekToEndOfFile()

                    if let appendMarker = appendMarker,
                      let encodedData = "\(appendMarker)\n".dataUsingEncoding(NSUTF8StringEncoding) {
                        _try({
                            self.logFileHandle?.writeData(encodedData)
                        },
                        catch: { (exception: NSException) in
                            self.owner._logln("Objective-C Exception occurred: \(exception)", logLevel: .Error)
                        })
                    }
                }
            }
            catch let error as NSError {
                owner._logln("Attempt to open log file for \(fileExists && shouldAppend ? "appending" : "writing") failed: \(error.localizedDescription)", logLevel: .Error)
                logFileHandle = nil
                return
            }

            #if swift(>=2.3)
                let logFileName = writeToFileURL.absoluteString!
            #else
                let logFileName = writeToFileURL.absoluteString
            #endif
            let logDetails = XCGLogDetails(logLevel: .Info, date: NSDate(), logMessage: "XCGLogger " + (fileExists && shouldAppend ? "appending" : "writing") + " log to: " + logFileName, functionName: "", fileName: "", lineNumber: 0)
            owner._logln(logDetails.logMessage, logLevel: logDetails.logLevel)
            if owner.logDestination(identifier) == nil {
                processInternalLogDetails(logDetails)
            }
        }
    }

    /// Close the log file.
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    private func closeFile() {
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
    public func rotateFile(archiveToFile: AnyObject) -> Bool {
        var archiveToFileURL: NSURL? = nil

        if archiveToFile is NSString {
            archiveToFileURL = NSURL.fileURLWithPath(archiveToFile as! String)
        }
        else if archiveToFile is NSURL {
            archiveToFileURL = archiveToFile as? NSURL
        }
        else {
            return false
        }

        if let archiveToFileURL = archiveToFileURL,
          let archiveToFilePath = archiveToFileURL.path,
          let writeToFileURL = writeToFileURL,
          let writeToFilePath = writeToFileURL.path {

            let fileManager: NSFileManager = NSFileManager.defaultManager()
            guard !fileManager.fileExistsAtPath(archiveToFilePath) else { return false }

            closeFile()

            do {
                try fileManager.moveItemAtPath(writeToFilePath, toPath: archiveToFilePath)
            }
            catch let error as NSError {
                openFile()
                owner._logln("Unable to rotate file \(writeToFilePath) to \(archiveToFilePath): \(error.localizedDescription)", logLevel: .Error)
                return false
            }

            owner._logln("Rotated file \(writeToFilePath) to \(archiveToFilePath)", logLevel: .Info)
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
    ///     - text:         Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    public override func output(logDetails: XCGLogDetails, text: String) {

        let outputClosure = {
            if let encodedData = "\(text)\n".dataUsingEncoding(NSUTF8StringEncoding) {
                _try({
                    self.logFileHandle?.writeData(encodedData)
                },
                catch: { (exception: NSException) in
                    self.owner._logln("Objective-C Exception occurred: \(exception)", logLevel: .Error)
                })
            }
        }

        if let logQueue = logQueue {
            dispatch_async(logQueue, outputClosure)
        }
        else {
            outputClosure()
        }
    }
}

// MARK: - XCGLogger
/// The main logging class
public class XCGLogger: CustomDebugStringConvertible {
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
        public static let versionString = "3.6.0"
    }
    public typealias constants = Constants // Preserve backwards compatibility: Constants should be capitalized since it's a type

    // MARK: - Enums
    /// Enum defining our log levels
    public enum LogLevel: Int, Comparable, CustomStringConvertible {
        case Verbose
        case Debug
        case Info
        case Warning
        case Error
        case Severe
        case None

        public var description: String {
            switch self {
            case .Verbose:
                return "Verbose"
            case .Debug:
                return "Debug"
            case .Info:
                return "Info"
            case .Warning:
                return "Warning"
            case .Error:
                return "Error"
            case .Severe:
                return "Severe"
            case .None:
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
            if let fgColorSpaceCorrected = fg.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) {
                self.fg = (Int(fgColorSpaceCorrected.redComponent * 255), Int(fgColorSpaceCorrected.greenComponent * 255), Int(fgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.fg = nil
            }

            if let bg = bg,
                let bgColorSpaceCorrected = bg.colorUsingColorSpaceName(NSCalibratedRGBColorSpace) {

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

    // MARK: - Properties (Options)
    /// Identifier for this logger object (should be unique)
    public var identifier: String = ""

    /// The log level of this logger, any logs received at this level or higher will be output to the log destinations
    public var outputLogLevel: LogLevel = .Debug {
        didSet {
            for index in 0 ..< logDestinations.count {
                logDestinations[index].outputLogLevel = outputLogLevel
            }
        }
    }

    /// Option: enable ANSI colour codes
    public var xcodeColorsEnabled: Bool = false

    /// The colours to use for each log level
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor] = [
        .Verbose: .lightGrey,
        .Debug: .darkGrey,
        .Info: .blue,
        .Warning: .orange,
        .Error: .red,
        .Severe: .whiteOnRed
    ]

    /// Option: a closure to execute whenever a logging method is called without a log message
    public var noMessageClosure: () -> Any? = { return "" }

    // MARK: - Properties
    /// The default dispatch queue used for logging
    public class var logQueue: dispatch_queue_t {
        struct Statics {
            static var logQueue = dispatch_queue_create(XCGLogger.Constants.logQueueIdentifier, nil)
        }

        return Statics.logQueue
    }

    /// The date formatter object to use when displaying the dates of log messages (internal storage)
    private var _dateFormatter: NSDateFormatter? = nil
    /// The date formatter object to use when displaying the dates of log messages
    public var dateFormatter: NSDateFormatter? {
        get {
            if _dateFormatter != nil {
                return _dateFormatter
            }

            let defaultDateFormatter = NSDateFormatter()
            defaultDateFormatter.locale = NSLocale.currentLocale()
            defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            _dateFormatter = defaultDateFormatter

            return _dateFormatter
        }
        set {
            _dateFormatter = newValue
        }
    }

    /// Array containing all of the log destinations for this logger
    public var logDestinations: [XCGLogDestinationProtocol] = []

    // MARK: - Life Cycle
    public init(identifier: String = "", includeDefaultDestinations: Bool = true) {
        self.identifier = identifier

        // Check if XcodeColors is installed and enabled
        if let xcodeColors = NSProcessInfo.processInfo().environment["XcodeColors"] {
            xcodeColorsEnabled = xcodeColors == "YES"
        }

        if includeDefaultDestinations {
            // Setup a standard console log destination
            addLogDestination(XCGConsoleLogDestination(owner: self, identifier: XCGLogger.Constants.baseConsoleLogDestinationIdentifier))
        }
    }

    // MARK: - Default instance
    /// Access the default XCGLogger object.
    ///
    /// - Parameters:
    ///     - None
    ///
    /// - Returns:  The default XCGLogger object
    ///
    public class func defaultInstance() -> XCGLogger {
        struct Statics {
            static let instance: XCGLogger = XCGLogger(identifier: XCGLogger.Constants.defaultInstanceIdentifier)
        }

        return Statics.instance
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
    public class func setup(logLevel: LogLevel = .Debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: AnyObject? = nil, fileLogLevel: LogLevel? = nil) {
        defaultInstance().setup(logLevel, showLogIdentifier: showLogIdentifier, showFunctionName: showFunctionName, showThreadName: showThreadName, showLogLevel: showLogLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, showDate: showDate, writeToFile: writeToFile)
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
    public func setup(logLevel: LogLevel = .Debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: AnyObject? = nil, fileLogLevel: LogLevel? = nil) {
        outputLogLevel = logLevel

        if let standardConsoleLogDestination = logDestination(XCGLogger.Constants.baseConsoleLogDestinationIdentifier) as? XCGConsoleLogDestination {
            standardConsoleLogDestination.showLogIdentifier = showLogIdentifier
            standardConsoleLogDestination.showFunctionName = showFunctionName
            standardConsoleLogDestination.showThreadName = showThreadName
            standardConsoleLogDestination.showLogLevel = showLogLevel
            standardConsoleLogDestination.showFileName = showFileNames
            standardConsoleLogDestination.showLineNumber = showLineNumbers
            standardConsoleLogDestination.showDate = showDate
            standardConsoleLogDestination.outputLogLevel = logLevel
        }

        if let writeToFile: AnyObject = writeToFile {
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

            addLogDestination(standardFileLogDestination)
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
    public class func logln(@autoclosure closure: () -> Any?, logLevel: LogLevel = .Debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func logln(logLevel: LogLevel = .Debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.defaultInstance().logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func logln(logLevel: LogLevel = .Debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.defaultInstance().logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func logln(@autoclosure closure: () -> Any?, logLevel: LogLevel = .Debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
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
    public func logln(logLevel: LogLevel = .Debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, @noescape closure: () -> Any?) {
        logln(logLevel, functionName: String(functionName), fileName: String(fileName), lineNumber: lineNumber, closure: closure)
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
    public func logln(logLevel: LogLevel = .Debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, @noescape closure: () -> Any?) {
        let enabledLogDestinations = self.logDestinations.filter({$0.isEnabledForLogLevel(logLevel)})
        guard enabledLogDestinations.count > 0 else { return }
        guard let closureResult = closure() else { return }

        let logDetails: XCGLogDetails = XCGLogDetails(logLevel: logLevel, date: NSDate(), logMessage: String(closureResult), functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        for logDestination in enabledLogDestinations {
            logDestination.processLogDetails(logDetails)
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
    public class func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel, closure: closure)
    }

    /// Execute some code only when at the specified log level.
    ///
    /// - Parameters:
    ///     - logLevel:     Specified log level **Default:** *Debug*.
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public func exec(logLevel: LogLevel = .Debug, @noescape closure: () -> () = {}) {
        guard isEnabledForLogLevel(logLevel) else {
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
    public func logAppDetails(selectedLogDestination: XCGLogDestinationProtocol? = nil) {
        let date = NSDate()

        var buildString = ""
        if let infoDictionary = NSBundle.mainBundle().infoDictionary {
            if let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as? String {
                // buildString = "Version: \(CFBundleShortVersionString) " // Note: Leaks in Swift versions prior to Swift 3
                buildString = "Version: " + CFBundleShortVersionString + " "
            }
            if let CFBundleVersion = infoDictionary["CFBundleVersion"] as? String {
                // buildString += "Build: \(CFBundleVersion) " // Note: Leaks in Swift versions prior to Swift 3
                buildString += "Build: " + CFBundleVersion + " "
            }
        }

        let processInfo: NSProcessInfo = NSProcessInfo.processInfo()
        let XCGLoggerVersionNumber = XCGLogger.Constants.versionString

        // let logDetails: Array<XCGLogDetails> = [XCGLogDetails(logLevel: .Info, date: date, logMessage: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
        //     XCGLogDetails(logLevel: .Info, date: date, logMessage: "XCGLogger Version: \(XCGLoggerVersionNumber) - LogLevel: \(outputLogLevel)", functionName: "", fileName: "", lineNumber: 0)] // Note: Leaks in Swift versions prior to Swift 3
        var logDetails: [XCGLogDetails] = []
        logDetails.append(XCGLogDetails(logLevel: .Info, date: date, logMessage: processInfo.processName + " " + buildString + "PID: " + String(processInfo.processIdentifier), functionName: "", fileName: "", lineNumber: 0))
        logDetails.append(XCGLogDetails(logLevel: .Info, date: date, logMessage: "XCGLogger Version: " + XCGLoggerVersionNumber + " - LogLevel: " + outputLogLevel.description, functionName: "", fileName: "", lineNumber: 0))

        for logDestination in (selectedLogDestination != nil ? [selectedLogDestination!] : logDestinations) {
            for logDetail in logDetails {
                guard logDestination.isEnabledForLogLevel(.Info) else {
                    continue
                }

                logDestination.processInternalLogDetails(logDetail)
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
    public class func verbose(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.defaultInstance().noMessageClosure)
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
    public class func verbose(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func verbose(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.defaultInstance().logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func verbose(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
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
    public func verbose(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func verbose(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func debug(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.defaultInstance().noMessageClosure)
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
    public class func debug(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func debug(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.defaultInstance().logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func debug(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
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
    public func debug(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func debug(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func info(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.defaultInstance().noMessageClosure)
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
    public class func info(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func info(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.defaultInstance().logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func info(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
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
    public func info(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func info(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func warning(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.defaultInstance().noMessageClosure)
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
    public class func warning(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func warning(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.defaultInstance().logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func warning(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
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
    public func warning(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func warning(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func error(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.defaultInstance().noMessageClosure)
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
    public class func error(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func error(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.defaultInstance().logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func error(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
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
    public func error(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func error(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func severe(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.defaultInstance().noMessageClosure)
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
    public class func severe(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func severe(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.defaultInstance().logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func severe(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
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
    public func severe(@autoclosure closure: () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public func severe(functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
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
    public class func verboseExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Verbose, closure: closure)
    }

    /// Execute some code only when at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public func verboseExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Verbose, closure: closure)
    }

    // MARK: * Debug
    /// Execute some code only when at the Debug or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public class func debugExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Debug, closure: closure)
    }

    /// Execute some code only when at the Debug or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public func debugExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Debug, closure: closure)
    }

    // MARK: * Info
    /// Execute some code only when at the Info or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public class func infoExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Info, closure: closure)
    }

    /// Execute some code only when at the Info or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public func infoExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Info, closure: closure)
    }

    // MARK: * Warning
    /// Execute some code only when at the Warning or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public class func warningExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Warning, closure: closure)
    }

    /// Execute some code only when at the Warning or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public func warningExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Warning, closure: closure)
    }

    // MARK: * Error
    /// Execute some code only when at the Error or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public class func errorExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Error, closure: closure)
    }

    /// Execute some code only when at the Error or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public func errorExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Error, closure: closure)
    }

    // MARK: * Severe
    /// Execute some code only when at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public class func severeExec(closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.Severe, closure: closure)
    }

    /// Execute some code only when at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    public func severeExec(closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.Severe, closure: closure)
    }

    // MARK: - Log destination methods
    /// Get the log destination with the specified identifier.
    ///
    /// - Parameters:
    ///     - identifier:   Identifier of the log destination to return.
    ///
    /// - Returns:  The log destination with the specified identifier, if one exists, nil otherwise.
    /// 
    public func logDestination(identifier: String) -> XCGLogDestinationProtocol? {
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
    public func addLogDestination(logDestination: XCGLogDestinationProtocol) -> Bool {
        let existingLogDestination: XCGLogDestinationProtocol? = self.logDestination(logDestination.identifier)
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
    public func removeLogDestination(logDestination: XCGLogDestinationProtocol) {
        removeLogDestination(logDestination.identifier)
    }

    /// Remove the log destination with the specified identifier from the logger.
    ///
    /// - Parameters:
    ///     - identifier:   The identifier of the log destination to remove.
    ///
    /// - Returns:  Nothing
    ///
    public func removeLogDestination(identifier: String) {
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
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
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
    private func _logln(logMessage: String, logLevel: LogLevel = .Debug) {

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: NSDate(), logMessage: logMessage, functionName: "", fileName: "", lineNumber: 0)
                }

                logDestination.processInternalLogDetails(logDetails!)
            }
        }
    }

    // MARK: - DebugPrintable
    public var debugDescription: String {
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
public func < (lhs:XCGLogger.LogLevel, rhs:XCGLogger.LogLevel) -> Bool {
    return lhs.rawValue < rhs.rawValue
}

func extractClassName(someObject: Any) -> String {
    return (someObject is Any.Type) ? "\(someObject)" : "\(someObject.dynamicType)"
}

// MARK: - Swiftier interface to the Objective-C exception handling functions
/// Throw an Objective-C exception with the specified name/message/info
///
/// - parameter name:     The name of the exception to throw
/// - parameter message:  The message to include in the exception (why it occurred)
/// - parameter userInfo: A dictionary with arbitrary info to be passed along with the exception
func _try(tryClosure: () -> (), catch catchClosure: (exception: NSException) -> (), finally finallyClosure: () -> () = {}) {
    _try(tryClosure, catchClosure, finallyClosure)
}

/// Throw an Objective-C exception with the specified name/message/info
///
/// - parameter name:     The name of the exception to throw
/// - parameter message:  The message to include in the exception (why it occurred)
/// - parameter userInfo: A dictionary with arbitrary info to be passed along with the exception
func _throw(name: String, message: String? = nil, userInfo: [NSObject: AnyObject]? = nil) {
    _throw(NSException(name: name, reason: message ?? name, userInfo: userInfo))
}
