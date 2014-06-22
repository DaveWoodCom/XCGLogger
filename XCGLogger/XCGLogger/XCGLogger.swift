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

class XCGLogger {
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
    var outputLogLevel: LogLevel = .Debug
    var showFileName: Bool = true
    var showLineNumber: Bool = true
    var showLogLevel: Bool = true

    /// #pragma mark - Properties (Internal)
    var dateFormatter: NSDateFormatter? = nil
    var writeToFileURL : NSURL? = nil {
        didSet {
            if logFileHandle {
                logFileHandle?.closeFile()
                logFileHandle = nil
            }

            if writeToFileURL {
                NSFileManager.defaultManager().createFileAtPath(writeToFileURL?.path, contents: nil, attributes: nil)
                var fileError : NSError? = nil
                logFileHandle = NSFileHandle.fileHandleForWritingToURL(writeToFileURL!, error: &fileError)
                if !logFileHandle {
                    _logln("Attempt to open log file for writing failed: \(fileError?.localizedDescription!)", logLevel: .Error)
                }
                else {
                    logAppDetails()
                    _logln("XCGLogger writing to log to: \(writeToFileURL!)", logLevel: .Info)
                }
            }
            else {
                logFileHandle = nil
            }
        }
    }
    var logFileHandle: NSFileHandle? = nil

    init() {
        dateFormatter = NSDateFormatter()
        dateFormatter!.locale = NSLocale.currentLocale()
        dateFormatter!.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    }

    deinit {
        // close file stream if open
        logFileHandle?.closeFile()
    }

    /// #pragma mark - Default instance
    class func defaultInstance() -> XCGLogger {
        struct statics {
            static let instance: XCGLogger = XCGLogger()
        }
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
        self.showLogLevel = showLogLevel;
        self.showFileName = showFileNames;
        self.showLineNumber = showLineNumbers;

        if let unwrappedWriteToFile : AnyObject = writeToFile {
            if unwrappedWriteToFile is NSString {
                writeToFileURL = NSURL.fileURLWithPath(unwrappedWriteToFile as String)
            }
            else if unwrappedWriteToFile is NSURL {
                writeToFileURL = unwrappedWriteToFile as? NSURL
            }
            else {
                writeToFileURL = nil
            }
        }
        else {
            writeToFileURL = nil
            logAppDetails()
        }
    }

    /// #pragma mark - Logging methods
    class func logln(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        self.defaultInstance().logln(logMessage, logLevel: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, functionNameDuplicate: functionNameDuplicate)
    }

    func logln(logMessage: String, logLevel: LogLevel = .Debug, functionName: String = __FUNCTION__, fileName: String = __FILE__, lineNumber: Int = __LINE__, functionNameDuplicate: String = __FUNCTION__) {
        if !isEnabledForLogLevel(logLevel) { return }

        // This is part of the hack to work around rdar://17219684
        var realFunctionName: String = functionName
        let functionNameDuplicateLength = functionNameDuplicate.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        let functionNameLength = functionName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        if functionNameLength < functionNameDuplicateLength {
            let range: Range = functionNameDuplicate.rangeOfString(functionName, options: .LiteralSearch)
            realFunctionName = functionNameDuplicate.stringByReplacingCharactersInRange(range, withString: "")
        }

        var extendedDetails: String = ""
        if showLogLevel {
            extendedDetails += "[" + logLevel.description() + "] "
        }

        if showFileName {
            extendedDetails += "[" + fileName.lastPathComponent + (showLineNumber ? ":" + String(lineNumber) : "") + "] "
        }
        else if showLineNumber {
            extendedDetails += "[" + String(lineNumber) + "] "
        }

        var now: NSDate = NSDate.date()
        var formattedDate: String = now.description
        if let unwrappedDataFormatter = dateFormatter {
            formattedDate = unwrappedDataFormatter.stringFromDate(now)
        }

        var fullLogMessage: String =  "\(formattedDate) \(extendedDetails)\(realFunctionName): \(logMessage)\n"

        print(fullLogMessage)
        logFileHandle?.writeData(fullLogMessage.dataUsingEncoding(NSUTF8StringEncoding))
    }

    func logAppDetails() {
        if !isEnabledForLogLevel(.Info) { return }

        var infoDictionary: NSDictionary = NSBundle.mainBundle().infoDictionary
        var processInfo: NSProcessInfo = NSProcessInfo.processInfo()
        let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as String
        let CFBundleVersion = infoDictionary["CFBundleVersion"] as String

        _logln("\(processInfo.processName!) (\(CFBundleShortVersionString) Build: \(CFBundleVersion)) PID: \(processInfo.processIdentifier)", logLevel: .Info)
        _logln("XCGLogger Version: \(XCGLoggerVersionNumber) - LogLevel: \(outputLogLevel.description())", logLevel: .Info)
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

    /// #pragma mark - Misc methods
    func isEnabledForLogLevel (logLevel: LogLevel) -> Bool {
        return logLevel.toRaw() >= self.outputLogLevel.toRaw()
    }

    func _logln(logMessage: String, logLevel: LogLevel = .Debug) {
        if !isEnabledForLogLevel(logLevel) { return }

        var extendedDetails: String = ""
        if showLogLevel {
            extendedDetails += "[" + logLevel.description() + "]: "
        }

        var now: NSDate = NSDate.date()
        var formattedDate: String = now.description
        if let unwrappedDataFormatter = dateFormatter {
            formattedDate = unwrappedDataFormatter.stringFromDate(now)
        }

        var fullLogMessage: String =  "\(formattedDate) \(extendedDetails)\(logMessage)\n"

        print(fullLogMessage)
        logFileHandle?.writeData(fullLogMessage.dataUsingEncoding(NSUTF8StringEncoding))
    }
}
