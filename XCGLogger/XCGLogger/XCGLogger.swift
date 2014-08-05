//
//  XCGLogger.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// Note:
// There is a bug in Xcode 6 Beta 1 (through at least Beta 4) where __FUNCTION__ has the function name appended to it each time it's used.
// Example:
//
//    func x() {
//        __FUNCTION__ // x()
//        __FUNCTION__ // x()x()
//        __FUNCTION__ // x()x()x()
//    }
//
// This obviously causes issues with this library. For now, I'm using a hack/workaround and once the bug is fixed in Xcode I'll remove the hack.
// More information about the bug can be seen in my radar on the issue: http://openradar.appspot.com/17219684 rdar://17219684

import Foundation

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
    public var dateFormatter: NSDateFormatter? = nil

    public init(owner: XCGLogger, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier

        dateFormatter = NSDateFormatter()
        dateFormatter!.locale = NSLocale.currentLocale()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
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

        print(fullLogMessage)
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

        print(fullLogMessage)
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel.toRaw() >= self.outputLogLevel.toRaw()
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
    public var dateFormatter: NSDateFormatter? = nil

    private var writeToFileURL : NSURL? = nil {
        didSet {
            openFile()
        }
    }
    private var logFileHandle: NSFileHandle? = nil

    public init(owner: XCGLogger, writeToFile: AnyObject, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier

        dateFormatter = NSDateFormatter()
        dateFormatter!.locale = NSLocale.currentLocale()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        if writeToFile is NSString {
            writeToFileURL = NSURL.fileURLWithPath(writeToFile as String)
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

        logFileHandle?.writeData(fullLogMessage.dataUsingEncoding(NSUTF8StringEncoding))
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

        logFileHandle?.writeData(fullLogMessage.dataUsingEncoding(NSUTF8StringEncoding))
    }

    // MARK: - Misc methods
    public func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel.toRaw() >= self.outputLogLevel.toRaw()
    }

    private func openFile() {
        if logFileHandle != nil {
            closeFile()
        }

        if writeToFileURL != nil {
            NSFileManager.defaultManager().createFileAtPath(writeToFileURL?.path, contents: nil, attributes: nil)
            var fileError : NSError? = nil
            logFileHandle = NSFileHandle.fileHandleForWritingToURL(writeToFileURL!, error: &fileError)
            if logFileHandle == nil {
                owner._logln("Attempt to open log file for writing failed: \(fileError?.localizedDescription!)", logLevel: .Error)
            }
            else {
                owner.logAppDetails(selectedLogDestination: self)

                let logDetails = XCGLogDetails(logLevel: .Info, date: NSDate.date(), logMessage: "XCGLogger writing to log to: \(writeToFileURL!)", functionName: "", fileName: "", lineNumber: 0)
                owner._logln(logDetails.logMessage, logLevel: logDetails.logLevel)
                processInternalLogDetails(logDetails)
            }
        }
        else {
            logFileHandle = nil
        }
    }

    private func closeFile() {
        logFileHandle?.closeFile()
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
        public static let versionString = "1.3"
    }

    // MARK: - Enums
    public enum LogLevel: Int {
        case Verbose = 1, Debug, Info, Error, Severe, None

        public func description() -> String {
            switch self {
                case .Verbose:
                    return "Verbose"
                case .Debug:
                    return "Debug"
                case .Info:
                    return "Info"
                case .Error:
                    return "Error"
                case .Severe:
                    return "Severe"
                case .None:
                    return "None"
                default:
                    return "Unknown"
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
    public var dateFormatter: NSDateFormatter? = nil
    public var logDestinations: Array<XCGLogDestinationProtocol> = []

    public init() {
        dateFormatter = NSDateFormatter()
        dateFormatter!.locale = NSLocale.currentLocale()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

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
                let standardConsoleLogDestination = unwrappedLogDestination as XCGConsoleLogDestination

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
    public class func logln(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().logln(logMessage, logLevel: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public func logln(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        let date = NSDate.date()

        // This is part of the hack to work around rdar://17219684
        var realFunctionName: String = functionName
        let functionNameDuplicateLength = functionNameDuplicate.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        let functionNameLength = functionName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        if functionNameLength < functionNameDuplicateLength {
            if let range: Range = functionNameDuplicate.rangeOfString(functionName, options: .LiteralSearch) {
                realFunctionName = functionNameDuplicate.stringByReplacingCharactersInRange(range, withString: "")
            }
        }

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: date, logMessage: logMessage, functionName: realFunctionName, fileName: fileName, lineNumber: lineNumber)
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
        let date = NSDate.date()
        var infoDictionary: NSDictionary = NSBundle.mainBundle().infoDictionary
        var processInfo: NSProcessInfo = NSProcessInfo.processInfo()
        let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as String
        let CFBundleVersion = infoDictionary["CFBundleVersion"] as String
        let XCGLoggerVersionNumber = XCGLogger.constants.versionString

        let logDetails: Array<XCGLogDetails> = [XCGLogDetails(logLevel: .Info, date: date, logMessage: "\(processInfo.processName!) (\(CFBundleShortVersionString) Build: \(CFBundleVersion)) PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
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
    public class func verbose(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().verbose(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public func verbose(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public class func debug(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().debug(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public func debug(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public class func info(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().info(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public func info(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public class func error(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().error(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public func error(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }
    
    public class func severe(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().severe(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    public func severe(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
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
        return logLevel.toRaw() >= self.outputLogLevel.toRaw()
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
        let date = NSDate.date()

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
