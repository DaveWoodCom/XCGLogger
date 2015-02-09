//
//  XCGLogger.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Foundation

private extension NSThread {
    class func dateFormatter(format: String, locale: NSLocale? = nil) -> NSDateFormatter? {

        let localeToUse = locale ?? NSLocale.currentLocale()

        // These next two lines are a bit of a hack to handle the fact that .threadDictionary changed from an optional to a non-optional between Xcode 6.1 and 6.1.1
        // This lets us use the same (albeit ugly) code in both cases.
        // TODO: Clean up at some point after 6.1.1 is officially released.
        let threadDictionary: NSMutableDictionary? = NSThread.currentThread().threadDictionary
        if let threadDictionary = threadDictionary {
            var dataFormatterCache: [String:NSDateFormatter]? = threadDictionary.objectForKey(XCGLogger.constants.nsdataFormatterCacheIdentifier) as? [String:NSDateFormatter]
            if dataFormatterCache == nil {
                dataFormatterCache = [String:NSDateFormatter]()
            }

            let formatterKey = format + "_" + localeToUse.localeIdentifier
            if let formatter = dataFormatterCache?[formatterKey] {
                return formatter
            }

            var formatter = NSDateFormatter()
            formatter.locale = localeToUse
            formatter.dateFormat = format
            dataFormatterCache?[formatterKey] = formatter

            threadDictionary[XCGLogger.constants.nsdataFormatterCacheIdentifier] = dataFormatterCache

            return formatter
        }

        return nil
    }
}

// MARK: - XCGLogDetails
// - Data structure to hold all info about a log message, passed to log destination classes
public struct XCGLogDetails {
    public var logLevel: XCGLogger.LogLevel
    public var date: NSDate
    public var logMessage: String
    public var functionName: String
    public var fileName: String
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
// - Protocol for output classes to conform to
public protocol XCGLogDestinationProtocol: DebugPrintable {
    var owner: XCGLogger {get set}
    var identifier: String {get set}
    var outputLogLevel: XCGLogger.LogLevel {get set}

    func processLogDetails(logDetails: XCGLogDetails)
    func processInternalLogDetails(logDetails: XCGLogDetails) // Same as processLogDetails but should omit function/file/line info
    func isEnabledForLogLevel(logLevel: XCGLogger.LogLevel) -> Bool
}

// MARK: - XCGConsoleLogDestination
// - A standard log destination that outputs log details to the console
public class XCGConsoleLogDestination : XCGLogDestinationProtocol, DebugPrintable {
    public var owner: XCGLogger
    public var identifier: String
    public var outputLogLevel: XCGLogger.LogLevel = .Debug

    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showLogLevel: Bool = true
    public var dateFormatter: NSDateFormatter? {
        return NSThread.dateFormatter("yyyy-MM-dd HH:mm:ss.SSS")
    }

    public init(owner: XCGLogger, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier
    }

    public func processLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""
        if showLogLevel {
            extendedDetails += "[" + logDetails.logLevel.description() + "] "
        }

        if showFileName {
            extendedDetails += "[" + logDetails.fileName.lastPathComponent + (showLineNumber ? ":" + String(logDetails.lineNumber) : "") + "] "
        }
        else if showLineNumber {
            extendedDetails += "[" + String(logDetails.lineNumber) + "] "
        }

        var formattedDate: String = logDetails.date.description
        if let unwrappedDataFormatter = dateFormatter {
            formattedDate = unwrappedDataFormatter.stringFromDate(logDetails.date)
        }

        var fullLogMessage: String =  "\(formattedDate) \(extendedDetails)\(logDetails.functionName): \(logDetails.logMessage)\n"

        dispatch_async(XCGLogger.logQueue) {
            print(fullLogMessage)
        }
    }

    public func processInternalLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""
        if showLogLevel {
            extendedDetails += "[" + logDetails.logLevel.description() + "] "
        }

        var formattedDate: String = logDetails.date.description
        if let unwrappedDataFormatter = dateFormatter {
            formattedDate = unwrappedDataFormatter.stringFromDate(logDetails.date)
        }

        var fullLogMessage: String =  "\(formattedDate) \(extendedDetails): \(logDetails.logMessage)\n"

        dispatch_async(XCGLogger.logQueue) {
            print(fullLogMessage)
        }
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            return "XCGConsoleLogDestination: \(identifier) - LogLevel: \(outputLogLevel.description()) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber)"
        }
    }
}

// MARK: - XCGFileLogDestination
// - A standard log destination that outputs log details to a file
public class XCGFileLogDestination : XCGLogDestinationProtocol, DebugPrintable {
    public var owner: XCGLogger
    public var identifier: String
    public var outputLogLevel: XCGLogger.LogLevel = .Debug

    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showLogLevel: Bool = true
    public var dateFormatter: NSDateFormatter? {
        return NSThread.dateFormatter("yyyy-MM-dd HH:mm:ss.SSS")
    }

    private var writeToFileURL : NSURL? = nil {
        didSet {
            openFile()
        }
    }
    private var logFileHandle: NSFileHandle? = nil

    public init(owner: XCGLogger, writeToFile: AnyObject, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier

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

    // MARK: - Logging methods
    public func processLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""
        if showLogLevel {
            extendedDetails += "[" + logDetails.logLevel.description() + "] "
        }

        if showFileName {
            extendedDetails += "[" + logDetails.fileName.lastPathComponent + (showLineNumber ? ":" + String(logDetails.lineNumber) : "") + "] "
        }
        else if showLineNumber {
            extendedDetails += "[" + String(logDetails.lineNumber) + "] "
        }

        var formattedDate: String = logDetails.date.description
        if let unwrappedDataFormatter = dateFormatter {
            formattedDate = unwrappedDataFormatter.stringFromDate(logDetails.date)
        }

        var fullLogMessage: String =  "\(formattedDate) \(extendedDetails)\(logDetails.functionName): \(logDetails.logMessage)\n"

        if let encodedData = fullLogMessage.dataUsingEncoding(NSUTF8StringEncoding) {
            logFileHandle?.writeData(encodedData)
        }
    }

    public func processInternalLogDetails(logDetails: XCGLogDetails) {
        var extendedDetails: String = ""
        if showLogLevel {
            extendedDetails += "[" + logDetails.logLevel.description() + "] "
        }

        var formattedDate: String = logDetails.date.description
        if let unwrappedDataFormatter = dateFormatter {
            formattedDate = unwrappedDataFormatter.stringFromDate(logDetails.date)
        }

        var fullLogMessage: String =  "\(formattedDate) \(extendedDetails): \(logDetails.logMessage)\n"

        if let encodedData = fullLogMessage.dataUsingEncoding(NSUTF8StringEncoding) {
            logFileHandle?.writeData(encodedData)
        }
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    private func openFile() {
        if logFileHandle != nil {
            closeFile()
        }

        if let unwrappedWriteToFileURL = writeToFileURL {
            if let path = unwrappedWriteToFileURL.path {
                NSFileManager.defaultManager().createFileAtPath(path, contents: nil, attributes: nil)
                var fileError : NSError? = nil
                logFileHandle = NSFileHandle(forWritingToURL: unwrappedWriteToFileURL, error: &fileError)
                if logFileHandle == nil {
                    owner._logln("Attempt to open log file for writing failed: \(fileError?.localizedDescription)", logLevel: .Error)
                }
                else {
                    owner.logAppDetails(selectedLogDestination: self)

                    let logDetails = XCGLogDetails(logLevel: .Info, date: NSDate(), logMessage: "XCGLogger writing to log to: \(unwrappedWriteToFileURL)", functionName: "", fileName: "", lineNumber: 0)
                    owner._logln(logDetails.logMessage, logLevel: logDetails.logLevel)
                    processInternalLogDetails(logDetails)
                }
            }
        }
    }

    private func closeFile() {
        logFileHandle?.closeFile()
        logFileHandle = nil
    }

    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            return "XCGFileLogDestination: \(identifier) - LogLevel: \(outputLogLevel.description()) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber)"
        }
    }
}

// MARK: - XCGLogger
// - The main logging class
public class XCGLogger : DebugPrintable {
    // MARK: - Constants
    public struct constants {
        public static let defaultInstanceIdentifier = "com.cerebralgardens.xcglogger.defaultInstance"
        public static let baseConsoleLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console"
        public static let baseFileLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.file"
        public static let nsdataFormatterCacheIdentifier = "com.cerebralgardens.xcglogger.nsdataFormatterCache"
        public static let logQueueIdentifier = "com.cerebralgardens.xcglogger.queue"
        public static let versionString = "1.8.1"
    }

    // MARK: - Enums
    public enum LogLevel: Int, Comparable {
        case Verbose
        case Debug
        case Info
        case Warning
        case Error
        case Severe
        case None

        public func description() -> String {
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

    // MARK: - Properties (Options)
    public var identifier: String = ""
    public var outputLogLevel: LogLevel = .Debug {
        didSet {
            for index in 0 ..< logDestinations.count {
                logDestinations[index].outputLogLevel = outputLogLevel
            }
        }
    }

    // MARK: - Properties
    public class var logQueue : dispatch_queue_t {
        struct Statics {
            static var logQueue = dispatch_queue_create(XCGLogger.constants.logQueueIdentifier, nil)
        }

        return Statics.logQueue
    }

    public var dateFormatter: NSDateFormatter? {
        return NSThread.dateFormatter("yyyy-MM-dd HH:mm:ss.SSS")
    }
    public var logDestinations: Array<XCGLogDestinationProtocol> = []

    public init() {
        // Setup a standard console log destination
        addLogDestination(XCGConsoleLogDestination(owner: self, identifier: XCGLogger.constants.baseConsoleLogDestinationIdentifier))
    }

    // MARK: - Default instance
    public class func defaultInstance() -> XCGLogger {
        struct statics {
            static let instance: XCGLogger = XCGLogger()
        }
        statics.instance.identifier = XCGLogger.constants.defaultInstanceIdentifier
        return statics.instance
    }
    public class func sharedInstance() -> XCGLogger {
        self.defaultInstance()._logln("sharedInstance() has been renamed to defaultInstance() to better reflect that it is not a true singleton. Please update your code, sharedInstance() will be removed in a future version.", logLevel: .Info)
        return self.defaultInstance()
    }

    // MARK: - Setup methods
    public class func setup(logLevel: LogLevel = .Debug, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, writeToFile: AnyObject? = nil) {
        defaultInstance().setup(logLevel: logLevel, showLogLevel: showLogLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, writeToFile: writeToFile)
    }

    public func setup(logLevel: LogLevel = .Debug, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, writeToFile: AnyObject? = nil) {
        outputLogLevel = logLevel;

        if let unwrappedLogDestination: XCGLogDestinationProtocol = logDestination(XCGLogger.constants.baseConsoleLogDestinationIdentifier) {
            if unwrappedLogDestination is XCGConsoleLogDestination {
                let standardConsoleLogDestination = unwrappedLogDestination as! XCGConsoleLogDestination

                standardConsoleLogDestination.showLogLevel = showLogLevel
                standardConsoleLogDestination.showFileName = showFileNames
                standardConsoleLogDestination.showLineNumber = showLineNumbers
                standardConsoleLogDestination.outputLogLevel = logLevel
            }
        }

        logAppDetails()

        if let unwrappedWriteToFile : AnyObject = writeToFile {
            // We've been passed a file to use for logging, set up a file logger
            let standardFileLogDestination: XCGFileLogDestination = XCGFileLogDestination(owner: self, writeToFile: unwrappedWriteToFile, identifier: XCGLogger.constants.baseFileLogDestinationIdentifier)

            standardFileLogDestination.showLogLevel = showLogLevel
            standardFileLogDestination.showFileName = showFileNames
            standardFileLogDestination.showLineNumber = showLineNumbers
            standardFileLogDestination.outputLogLevel = logLevel

            addLogDestination(standardFileLogDestination)
        }
    }

    // MARK: - Logging methods
    public class func logln(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().logln(logMessage, logLevel: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func logln(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        let date = NSDate()

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: date, logMessage: logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                }

                logDestination.processLogDetails(logDetails!)
            }
        }
    }

    public class func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: logLevel, closure: closure)
    }

    public func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        if (!isEnabledForLogLevel(logLevel)) {
            return
        }

        closure()
    }

    public func logAppDetails(selectedLogDestination: XCGLogDestinationProtocol? = nil) {
        let date = NSDate()

        var buildString = ""
        if let infoDictionary = NSBundle.mainBundle().infoDictionary {
            if let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as? String {
                buildString = "Version: \(CFBundleShortVersionString) "
            }
            if let CFBundleVersion = infoDictionary["CFBundleVersion"] as? String {
                buildString += "Build: \(CFBundleVersion) "
            }
        }

        let processInfo: NSProcessInfo = NSProcessInfo.processInfo()
        let XCGLoggerVersionNumber = XCGLogger.constants.versionString

        let logDetails: Array<XCGLogDetails> = [XCGLogDetails(logLevel: .Info, date: date, logMessage: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
            XCGLogDetails(logLevel: .Info, date: date, logMessage: "XCGLogger Version: \(XCGLoggerVersionNumber) - LogLevel: \(outputLogLevel.description())", functionName: "", fileName: "", lineNumber: 0)]

        for logDestination in (selectedLogDestination != nil ? [selectedLogDestination!] : logDestinations) {
            for logDetail in logDetails {
                if !logDestination.isEnabledForLogLevel(.Info) {
                    continue;
                }

                logDestination.processInternalLogDetails(logDetail)
            }
        }
    }

    // MARK: - Convenience logging methods
    public class func verbose(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().verbose(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func verbose(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logMessage, logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public class func debug(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().debug(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func debug(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logMessage, logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public class func info(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().info(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func info(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logMessage, logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public class func warning(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().warning(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func warning(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logMessage, logLevel: .Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func error(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().error(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func error(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logMessage, logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }
    
    public class func severe(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.defaultInstance().severe(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public func severe(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__) {
        self.logln(logMessage, logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    public class func verboseExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Verbose, closure: closure)
    }

    public func verboseExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Verbose, closure: closure)
    }
    
    public class func debugExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Debug, closure: closure)
    }

    public func debugExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Debug, closure: closure)
    }
    
    public class func infoExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Info, closure: closure)
    }

    public func infoExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Info, closure: closure)
    }
    
    public class func warningExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Warning, closure: closure)
    }

    public func warningExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Warning, closure: closure)
    }

    public class func errorExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Error, closure: closure)
    }

    public func errorExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Error, closure: closure)
    }
    
    public class func severeExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Severe, closure: closure)
    }

    public func severeExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Severe, closure: closure)
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }

    public func logDestination(identifier: String) -> XCGLogDestinationProtocol? {
        for logDestination in logDestinations {
            if logDestination.identifier == identifier {
                return logDestination
            }
        }

        return nil
    }

    public func addLogDestination(logDestination: XCGLogDestinationProtocol) -> Bool {
        let existingLogDestination: XCGLogDestinationProtocol? = self.logDestination(logDestination.identifier)
        if existingLogDestination != nil {
            return false
        }

        logDestinations.append(logDestination)
        return true
    }

    public func removeLogDestination(logDestination: XCGLogDestinationProtocol) {
        removeLogDestination(logDestination.identifier)
    }

    public func removeLogDestination(identifier: String) {
        logDestinations = logDestinations.filter({$0.identifier != identifier})
    }

    // MARK: - Private methods
    private func _logln(logMessage: String, logLevel: LogLevel = .Debug) {
        let date = NSDate()

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: date, logMessage: logMessage, functionName: "", fileName: "", lineNumber: 0)
                }

                logDestination.processInternalLogDetails(logDetails!)
            }
        }
    }

    // MARK: - DebugPrintable
    public var debugDescription: String {
        get {
            var description: String = "XCGLogger: \(identifier) - logDestinations: \r"
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

// This operation shouldn't be required, since providing < is all that is needed, however, the compiler crashes when optimization is enabled.
// Adding this operator works around the optimization bug.
// Thanks to @beltex https://github.com/beltex for helping to narrow this down.
public func >= (lhs:XCGLogger.LogLevel, rhs:XCGLogger.LogLevel) -> Bool {
    return lhs.rawValue > rhs.rawValue || lhs.rawValue == rhs.rawValue
}
