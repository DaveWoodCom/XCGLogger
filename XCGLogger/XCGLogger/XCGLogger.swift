//
//  XCGLogger.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// Note:
// There is a bug in Xcode 6 Beta 1 (6A215l) where __FUNCTION__ has the function name appended to it each time it's used.
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

/// #pragma mark - XCGLogDetails
/// - Data structure to hold all info about a log message, passed to log destination classes
struct XCGLogDetails {
    var logLevel: XCGLogger.LogLevel
    var date: NSDate
    var logMessage: String
    var functionName: String
    var fileName: String
    var lineNumber: Int
}

/// #pragma mark - XCGLogDestinationProtocol
/// - Protocol for output classes to conform too
protocol XCGLogDestinationProtocol: DebugPrintable {
    var owner: XCGLogger {get set}
    var identifier: String {get set}
    var outputLogLevel: XCGLogger.LogLevel {get set}

    func processLogDetails(logDetails: XCGLogDetails)
    func processInternalLogDetails(logDetails: XCGLogDetails) // Same as processLogDetails but should omit function/file/line info
    func isEnabledForLogLevel(logLevel: XCGLogger.LogLevel) -> Bool
}

/// #pragma mark - XCGConsoleLogDestination
/// - A standard log destination that outputs log details to the console
class XCGConsoleLogDestination : XCGLogDestinationProtocol, DebugPrintable {
    var owner: XCGLogger
    var identifier: String
    var outputLogLevel: XCGLogger.LogLevel = .Debug

    var showFileName: Bool = true
    var showLineNumber: Bool = true
    var showLogLevel: Bool = true
    var dateFormatter: NSDateFormatter? = nil

    init(owner: XCGLogger, identifier: String = "") {
        self.owner = owner
        self.identifier = identifier

        dateFormatter = NSDateFormatter()
        dateFormatter!.locale = NSLocale.currentLocale()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }

    func processLogDetails(logDetails: XCGLogDetails) {
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

    func processInternalLogDetails(logDetails: XCGLogDetails) {
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

    /// #pragma mark - Misc methods
    func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel.toRaw() >= self.outputLogLevel.toRaw()
    }

    /// #pragma mark - DebugPrintable
    var debugDescription: String {
        get {
            return "XCGConsoleLogDestination: \(identifier) - LogLevel: \(outputLogLevel.description()) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber)"
        }
    }
}

/// #pragma mark - XCGFileLogDestination
/// - A standard log destination that outputs log details to a file
class XCGFileLogDestination : XCGLogDestinationProtocol {
    var owner: XCGLogger
    var identifier: String
    var outputLogLevel: XCGLogger.LogLevel = .Debug

    var showFileName: Bool = true
    var showLineNumber: Bool = true
    var showLogLevel: Bool = true
    var dateFormatter: NSDateFormatter? = nil

    var writeToFileURL : NSURL? = nil {
        didSet {
            openFile()
        }
    }
    var logFileHandle: NSFileHandle? = nil

    init(owner: XCGLogger, writeToFile: AnyObject, identifier: String = "") {
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

    /// #pragma mark - Logging methods
    func processLogDetails(logDetails: XCGLogDetails) {
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

    func processInternalLogDetails(logDetails: XCGLogDetails) {
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

    /// #pragma mark - Misc methods
    func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel.toRaw() >= self.outputLogLevel.toRaw()
    }

    func openFile() {
        if logFileHandle {
            closeFile()
        }

        if writeToFileURL {
            NSFileManager.defaultManager().createFileAtPath(writeToFileURL?.path, contents: nil, attributes: nil)
            var fileError : NSError? = nil
            logFileHandle = NSFileHandle.fileHandleForWritingToURL(writeToFileURL!, error: &fileError)
            if !logFileHandle {
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

    func closeFile() {
        logFileHandle?.closeFile()
    }

    /// #pragma mark - DebugPrintable
    var debugDescription: String {
        get {
            return "XCGFileLogDestination: \(identifier) - LogLevel: \(outputLogLevel.description()) showLogLevel: \(showLogLevel) showFileName: \(showFileName) showLineNumber: \(showLineNumber)"
        }
    }
}

/// #pragma mark - XCGLogger
/// The main logging class
class XCGLogger : DebugPrintable {
    /// #pragma mark - Constants
    struct constants {
        static let defaultInstanceIdentifier = "com.cerebralgardens.xcglogger.defaultInstance"
        static let baseConsoleLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console"
        static let baseFileLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.file"
        static let versionString = "1.2"
    }

    /// #pragma mark - Enums
    enum LogLevel: Int {
        case Verbose = 1, Debug, Info, Error, Severe, None

        func description() -> String {
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

    /// #pragma mark - Properties (Options)
    var identifier: String = ""
    var outputLogLevel: LogLevel = .Debug {
        didSet {
            for index in 0 ..< logDestinations.count {
                logDestinations[index].outputLogLevel = outputLogLevel
            }
        }
    }

    /// #pragma mark - Properties (Internal)
    var dateFormatter: NSDateFormatter? = nil
    var logDestinations: Array<XCGLogDestinationProtocol> = []

    init() {
        dateFormatter = NSDateFormatter()
        dateFormatter!.locale = NSLocale.currentLocale()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"

        // Setup a standard console log destination
        addLogDestination(XCGConsoleLogDestination(owner: self, identifier: XCGLogger.constants.baseConsoleLogDestinationIdentifier))
    }

    /// #pragma mark - Default instance
    class func defaultInstance() -> XCGLogger {
        struct statics {
            static let instance: XCGLogger = XCGLogger()
        }
        statics.instance.identifier = XCGLogger.constants.defaultInstanceIdentifier
        return statics.instance
    }
    class func sharedInstance() -> XCGLogger {
        self.defaultInstance()._logln("sharedInstance() has been renamed to defaultInstance() to better reflect that it is not a true singleton. Please update your code, sharedInstance() will be removed in a future version.", logLevel: .Info)
        return self.defaultInstance()
    }

    /// #pragma mark - Setup methods
    class func setup(logLevel: LogLevel = .Debug, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, writeToFile: AnyObject? = nil) {
        defaultInstance().setup(logLevel: logLevel, showLogLevel: showLogLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, writeToFile: writeToFile)
    }

    func setup(logLevel: LogLevel = .Debug, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, writeToFile: AnyObject? = nil) {
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

    /// #pragma mark - Logging methods
    class func logln(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().logln(logMessage, logLevel: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    func logln(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        let date = NSDate.date()

        // This is part of the hack to work around rdar://17219684
        var realFunctionName: String = functionName
        let functionNameDuplicateLength = functionNameDuplicate.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        let functionNameLength = functionName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        if functionNameLength < functionNameDuplicateLength {
            let range: Range? = functionNameDuplicate.rangeOfString(functionName, options: .LiteralSearch)
            if (range) {
                realFunctionName = functionNameDuplicate.stringByReplacingCharactersInRange(range!, withString: "")
            }
        }

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if !logDetails {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: date, logMessage: logMessage, functionName: realFunctionName, fileName: fileName, lineNumber: lineNumber)
                }

                logDestination.processLogDetails(logDetails!)
            }
        }
    }

    class func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: logLevel, closure: closure)
    }

    func exec(logLevel: LogLevel = .Debug, closure: () -> () = {}) {
        if (!isEnabledForLogLevel(logLevel)) {
            return
        }

        closure()
    }

    func logAppDetails(selectedLogDestination: XCGLogDestinationProtocol? = nil) {
        let date = NSDate.date()
        var infoDictionary: NSDictionary = NSBundle.mainBundle().infoDictionary
        var processInfo: NSProcessInfo = NSProcessInfo.processInfo()
        let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as String
        let CFBundleVersion = infoDictionary["CFBundleVersion"] as String
        let XCGLoggerVersionNumber = XCGLogger.constants.versionString

        let logDetails: Array<XCGLogDetails> = [XCGLogDetails(logLevel: .Info, date: date, logMessage: "\(processInfo.processName!) (\(CFBundleShortVersionString) Build: \(CFBundleVersion)) PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
            XCGLogDetails(logLevel: .Info, date: date, logMessage: "XCGLogger Version: \(XCGLoggerVersionNumber) - LogLevel: \(outputLogLevel.description())", functionName: "", fileName: "", lineNumber: 0)]

        for logDestination in (selectedLogDestination ? [selectedLogDestination!] : logDestinations) {
            for logDetail in logDetails {
                if !logDestination.isEnabledForLogLevel(.Info) {
                    continue;
                }

                logDestination.processInternalLogDetails(logDetail)
            }
        }
    }

    /// #pragma mark - Convenience logging methods
    class func verbose(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().verbose(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    func verbose(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    class func debug(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().debug(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    func debug(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    class func info(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().info(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    func info(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    class func error(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().error(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    func error(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }
    
    class func severe(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().severe(logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    func severe(logMessage: String, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.logln(logMessage, logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    class func verboseExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Verbose, closure: closure)
    }

    func verboseExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Verbose, closure: closure)
    }
    
    class func debugExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Debug, closure: closure)
    }

    func debugExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Debug, closure: closure)
    }
    
    class func infoExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Info, closure: closure)
    }

    func infoExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Info, closure: closure)
    }
    
    class func errorExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Error, closure: closure)
    }

    func errorExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Error, closure: closure)
    }
    
    class func severeExec(closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel: XCGLogger.LogLevel.Severe, closure: closure)
    }

    func severeExec(closure: () -> () = {}) {
        self.exec(logLevel: XCGLogger.LogLevel.Severe, closure: closure)
    }

    /// #pragma mark - Misc methods
    func isEnabledForLogLevel (logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel.toRaw() >= self.outputLogLevel.toRaw()
    }

    func logDestination(identifier: String) -> XCGLogDestinationProtocol? {

        for logDestination in logDestinations {
            if logDestination.identifier == identifier {
                return logDestination
            }
        }

        return nil
    }

    func addLogDestination(logDestination: XCGLogDestinationProtocol) -> Bool {
        let existingLogDestination: XCGLogDestinationProtocol? = self.logDestination(logDestination.identifier)
        if existingLogDestination {
            return false
        }

        logDestinations.append(logDestination)
        return true
    }

    func removeLogDestination(logDestination: XCGLogDestinationProtocol) {
        removeLogDestination(logDestination.identifier)
    }

    func removeLogDestination(identifier: String) {
        logDestinations = logDestinations.filter({$0.identifier != identifier})
    }

    /// #pragma mark - Private methods
    func _logln(logMessage: String, logLevel: LogLevel = .Debug) {
        let date = NSDate.date()

        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if !logDetails {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: date, logMessage: logMessage, functionName: "", fileName: "", lineNumber: 0)
                }

                logDestination.processInternalLogDetails(logDetails!)
            }
        }
    }

    /// #pragma mark - DebugPrintable
    var debugDescription: String {
        get {
            var description: String = "XCGLogger: \(identifier) - logDestinations: \r"
            for logDestination in logDestinations {
                description += "\t \(logDestination.debugDescription)\r"
            }

            return description
        }
    }
}
