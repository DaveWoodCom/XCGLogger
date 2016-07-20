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
// - Data structure to hold all info about a log message, passed to log destination classes
public struct XCGLogDetails {
    public var logLevel: XCGLogger.LogLevel
    public var date: Date
    public var logMessage: String
    public var functionName: String
    public var fileName: String
    public var lineNumber: Int
    
    public init(logLevel: XCGLogger.LogLevel, date: Date, logMessage: String, functionName: String, fileName: String, lineNumber: Int) {
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
public protocol XCGLogDestinationProtocol: CustomDebugStringConvertible {
    var owner: XCGLogger {get set}
    var identifier: String {get set}
    var outputLogLevel: XCGLogger.LogLevel {get set}
    
    func processLogDetails(_ logDetails: XCGLogDetails)
    func processInternalLogDetails(_ logDetails: XCGLogDetails) // Same as processLogDetails but should omit function/file/line info
    func isEnabledForLogLevel(_ logLevel: XCGLogger.LogLevel) -> Bool
}

// MARK: - XCGBaseLogDestination
// - A base class log destination that doesn't actually output the log anywhere and is intented to be subclassed
public class XCGBaseLogDestination: XCGLogDestinationProtocol, CustomDebugStringConvertible {
    // MARK: - Properties
    public var owner: XCGLogger
    public var identifier: String
    public var outputLogLevel: XCGLogger.LogLevel = .debug
    
    public var showLogIdentifier: Bool = false
    public var showFunctionName: Bool = true
    public var showThreadName: Bool = false
    public var showFileName: Bool = true
    public var showLineNumber: Bool = true
    public var showLogLevel: Bool = true
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
    public func processLogDetails(_ logDetails: XCGLogDetails) {
        var extendedDetails: String = ""
        
        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.string(from: logDetails.date)
            }
            
            extendedDetails += "\(formattedDate) "
        }
        
        if showLogLevel {
            extendedDetails += "[\(logDetails.logLevel)] "
        }
        
        if showLogIdentifier {
            extendedDetails += "[\(owner.identifier)] "
        }
        
        if showThreadName {
            if Thread.isMainThread {
                extendedDetails += "[main] "
            }
            else {
                if let threadName = Thread.current.name , !threadName.isEmpty {
                    extendedDetails += "[" + threadName + "] "
                }
                else {
                    extendedDetails += "[" + String(format:"%p", Thread.current) + "] "
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
            extendedDetails += "\(logDetails.functionName) "
        }
        
        output(logDetails, text: "\(extendedDetails)> \(logDetails.logMessage)")
    }
    
    public func processInternalLogDetails(_ logDetails: XCGLogDetails) {
        var extendedDetails: String = ""
        
        if showDate {
            var formattedDate: String = logDetails.date.description
            if let dateFormatter = owner.dateFormatter {
                formattedDate = dateFormatter.string(from: logDetails.date)
            }
            
            extendedDetails += "\(formattedDate) "
        }
        
        if showLogLevel {
            extendedDetails += "[\(logDetails.logLevel)] "
        }
        
        if showLogIdentifier {
            extendedDetails += "[\(owner.identifier)] "
        }
        
        output(logDetails, text: "\(extendedDetails)> \(logDetails.logMessage)")
    }
    
    // MARK: - Misc methods
    public func isEnabledForLogLevel (_ logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }
    
    // MARK: - Methods that must be overriden in subclasses
    public func output(_ logDetails: XCGLogDetails, text: String) {
        // Do something with the text in an overridden version of this method
        precondition(false, "Must override this")
    }
}

// MARK: - XCGConsoleLogDestination
// - A standard log destination that outputs log details to the console
public class XCGConsoleLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    public var logQueue: DispatchQueue? = nil
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil
    
    // MARK: - Misc Methods
    public override func output(_ logDetails: XCGLogDetails, text: String) {
        
        let outputClosure = {
            let adjustedText: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.logLevel] , self.owner.xcodeColorsEnabled {
                adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedText = text
            }
            
            print("\(adjustedText)")
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
// - A standard log destination that outputs log details to the console using NSLog instead of println
public class XCGNSLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    public var logQueue: DispatchQueue? = nil
    public var xcodeColors: [XCGLogger.LogLevel: XCGLogger.XcodeColor]? = nil
    
    public override var showDate: Bool {
        get {
            return false
        }
        set {
            // ignored, NSLog adds the date, so we always want showDate to be false in this subclass
        }
    }
    
    // MARK: - Misc Methods
    public override func output(_ logDetails: XCGLogDetails, text: String) {
        
        let outputClosure = {
            let adjustedText: String
            if let xcodeColor = (self.xcodeColors ?? self.owner.xcodeColors)[logDetails.logLevel] , self.owner.xcodeColorsEnabled {
                adjustedText = "\(xcodeColor.format())\(text)\(XCGLogger.XcodeColor.reset)"
            }
            else {
                adjustedText = text
            }
            
            NSLog("%@", adjustedText)
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
// - A standard log destination that outputs log details to a file
public class XCGFileLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    public var logQueue: DispatchQueue? = nil
    private var writeToFileURL: URL? = nil {
        didSet {
            openFile()
        }
    }
    private var logFileHandle: FileHandle? = nil
    
    // MARK: - Life Cycle
    public init(owner: XCGLogger, writeToFile: AnyObject, identifier: String = "") {
        super.init(owner: owner, identifier: identifier)
        
        if let writeToFile = writeToFile as? String {
            writeToFileURL = URL(fileURLWithPath: writeToFile)
        }
        else if let writeToFile = writeToFile as? URL {
            writeToFileURL = writeToFile
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
    private func openFile() {
        if logFileHandle != nil {
            closeFile()
        }
        
        if let writeToFileURL = writeToFileURL,
            let path = writeToFileURL.path {
            
            FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            do {
                logFileHandle = try FileHandle(forWritingTo: writeToFileURL)
            }
            catch let error as NSError {
                owner._logln("Attempt to open log file for writing failed: \(error.localizedDescription)", logLevel: .error)
                logFileHandle = nil
                return
            }
            
            owner.logAppDetails(self)
            
            let logDetails = XCGLogDetails(logLevel: .info, date: Date(), logMessage: "XCGLogger writing to log to: \(writeToFileURL)", functionName: "", fileName: "", lineNumber: 0)
            owner._logln(logDetails.logMessage, logLevel: logDetails.logLevel)
            processInternalLogDetails(logDetails)
        }
    }
    
    private func closeFile() {
        logFileHandle?.closeFile()
        logFileHandle = nil
    }
    
    // MARK: - Misc Methods
    public override func output(_ logDetails: XCGLogDetails, text: String) {
        
        let outputClosure = {
            if let encodedData = "\(text)\n".data(using: String.Encoding.utf8) {
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
// - The main logging class
public class XCGLogger: CustomDebugStringConvertible {
    // MARK: - Constants
    public struct Constants {
        public static let defaultInstanceIdentifier = "com.cerebralgardens.xcglogger.defaultInstance"
        public static let baseConsoleLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console"
        public static let nslogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.console.nslog"
        public static let baseFileLogDestinationIdentifier = "com.cerebralgardens.xcglogger.logdestination.file"
        public static let logQueueIdentifier = "com.cerebralgardens.xcglogger.queue"
        public static let nsdataFormatterCacheIdentifier = "com.cerebralgardens.xcglogger.nsdataFormatterCache"
        public static let versionString = "3.3"
    }
    public typealias constants = Constants // Preserve backwards compatibility: Constants should be capitalized since it's a type
    
    // MARK: - Enums
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
    
    public struct XcodeColor {
        public static let escape = "\u{001b}["
        public static let resetFg = "\u{001b}[fg;"
        public static let resetBg = "\u{001b}[bg;"
        public static let reset = "\u{001b}[;"
        
        public var fg: (Int, Int, Int)? = nil
        public var bg: (Int, Int, Int)? = nil
        
        public func format() -> String {
            guard fg != nil || bg != nil else {
                // neither set, return reset value
                return XcodeColor.reset
            }
            
            var format: String = ""
            
            if let fg = fg {
                format += "\(XcodeColor.escape)fg\(fg.0),\(fg.1),\(fg.2);"
            }
            else {
                format += XcodeColor.resetFg
            }
            
            if let bg = bg {
                format += "\(XcodeColor.escape)bg\(bg.0),\(bg.1),\(bg.2);"
            }
            else {
                format += XcodeColor.resetBg
            }
            
            return format
        }
        
        public init(fg: (Int, Int, Int)? = nil, bg: (Int, Int, Int)? = nil) {
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
        
        public static let red: XcodeColor = {
            return XcodeColor(fg: (255, 0, 0))
        }()
        
        public static let green: XcodeColor = {
            return XcodeColor(fg: (0, 255, 0))
        }()
        
        public static let blue: XcodeColor = {
            return XcodeColor(fg: (0, 0, 255))
        }()
        
        public static let black: XcodeColor = {
            return XcodeColor(fg: (0, 0, 0))
        }()
        
        public static let white: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255))
        }()
        
        public static let lightGrey: XcodeColor = {
            return XcodeColor(fg: (211, 211, 211))
        }()
        
        public static let darkGrey: XcodeColor = {
            return XcodeColor(fg: (169, 169, 169))
        }()
        
        public static let orange: XcodeColor = {
            return XcodeColor(fg: (255, 165, 0))
        }()
        
        public static let whiteOnRed: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0))
        }()
        
        public static let darkGreen: XcodeColor = {
            return XcodeColor(fg: (0, 128, 0))
        }()
    }
    
    // MARK: - Properties (Options)
    public var identifier: String = ""
    public var outputLogLevel: LogLevel = .debug {
        didSet {
            for index in 0 ..< logDestinations.count {
                logDestinations[index].outputLogLevel = outputLogLevel
            }
        }
    }
    
    public var xcodeColorsEnabled: Bool = false
    public var xcodeColors: [LogLevel: XcodeColor] = [
        .verbose: .lightGrey,
        .debug: .darkGrey,
        .info: .blue,
        .warning: .orange,
        .error: .red,
        .severe: .whiteOnRed
    ]
    
    // MARK: - Properties
    public class var logQueue: DispatchQueue {
        struct Statics {
            static var logQueue = DispatchQueue(label: XCGLogger.Constants.logQueueIdentifier, attributes: [])
        }
        
        return Statics.logQueue
    }
    
    private var _dateFormatter: DateFormatter? = nil
    public var dateFormatter: DateFormatter? {
        get {
            if _dateFormatter != nil {
                return _dateFormatter
            }
            
            let defaultDateFormatter = DateFormatter()
            defaultDateFormatter.locale = Locale.current
            defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            _dateFormatter = defaultDateFormatter
            
            return _dateFormatter
        }
        set {
            _dateFormatter = newValue
        }
    }
    
    public var logDestinations: Array<XCGLogDestinationProtocol> = []
    
    // MARK: - Life Cycle
    public init(identifier: String = "", includeDefaultDestinations: Bool = true) {
        self.identifier = identifier
        
        // Check if XcodeColors is installed and enabled
        if let xcodeColors = ProcessInfo.processInfo.environment["XcodeColors"] {
            xcodeColorsEnabled = xcodeColors == "YES"
        }
        
        if includeDefaultDestinations {
            // Setup a standard console log destination
            addLogDestination(XCGConsoleLogDestination(owner: self, identifier: XCGLogger.Constants.baseConsoleLogDestinationIdentifier))
        }
    }
    
    // MARK: - Default instance
    public class func defaultInstance() -> XCGLogger {
        struct Statics {
            static let instance: XCGLogger = XCGLogger(identifier: XCGLogger.Constants.defaultInstanceIdentifier)
        }
        
        return Statics.instance
    }
    
    // MARK: - Setup methods
    public class func setup(_ logLevel: LogLevel = .debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: AnyObject? = nil, fileLogLevel: LogLevel? = nil) {
        defaultInstance().setup(logLevel, showLogIdentifier: showLogIdentifier, showFunctionName: showFunctionName, showThreadName: showThreadName, showLogLevel: showLogLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, showDate: showDate, writeToFile: writeToFile)
    }
    
    public func setup(_ logLevel: LogLevel = .debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLogLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: AnyObject? = nil, fileLogLevel: LogLevel? = nil) {
        outputLogLevel = logLevel;
        
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
        
        logAppDetails()
        
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
    }
    
    // MARK: - Logging methods
    public class func logln(_ closure: @autoclosure () -> String?, logLevel: LogLevel = .debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public class func logln(_ logLevel: LogLevel = .debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.defaultInstance().logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func logln(_ closure: @autoclosure () -> String?, logLevel: LogLevel = .debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func logln(_ logLevel: LogLevel = .debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    if let logMessage = closure() {
                        logDetails = XCGLogDetails(logLevel: logLevel, date: Date(), logMessage: logMessage, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
                    }
                    else {
                        break
                    }
                }
                
                logDestination.processLogDetails(logDetails!)
            }
        }
    }
    
    public class func exec(_ logLevel: LogLevel = .debug, closure: () -> () = {}) {
        self.defaultInstance().exec(logLevel, closure: closure)
    }
    
    public func exec(_ logLevel: LogLevel = .debug, closure: () -> () = {}) {
        if (!isEnabledForLogLevel(logLevel)) {
            return
        }
        
        closure()
    }
    
    public func logAppDetails(_ selectedLogDestination: XCGLogDestinationProtocol? = nil) {
        let date = Date()
        
        var buildString = ""
        if let infoDictionary = Bundle.main.infoDictionary {
            if let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as? String {
                buildString = "Version: \(CFBundleShortVersionString) "
            }
            if let CFBundleVersion = infoDictionary["CFBundleVersion"] as? String {
                buildString += "Build: \(CFBundleVersion) "
            }
        }
        
        let processInfo: ProcessInfo = ProcessInfo.processInfo
        let XCGLoggerVersionNumber = XCGLogger.Constants.versionString
        
        let logDetails: Array<XCGLogDetails> = [XCGLogDetails(logLevel: .info, date: date, logMessage: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
                                                XCGLogDetails(logLevel: .info, date: date, logMessage: "XCGLogger Version: \(XCGLoggerVersionNumber) - LogLevel: \(outputLogLevel)", functionName: "", fileName: "", lineNumber: 0)]
        
        for logDestination in (selectedLogDestination != nil ? [selectedLogDestination!] : logDestinations) {
            for logDetail in logDetails {
                if !logDestination.isEnabledForLogLevel(.info) {
                    continue;
                }
                
                logDestination.processInternalLogDetails(logDetail)
            }
        }
    }
    
    // MARK: - Convenience logging methods
    // MARK: * Verbose
    public class func verbose(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public class func verbose(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.defaultInstance().logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func verbose(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func verbose(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line,closure: @noescape () -> String?) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    // MARK: * Debug
    public class func debug(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public class func debug(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.defaultInstance().logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func debug(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func debug(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    // MARK: * Info
    public class func info(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public class func info(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.defaultInstance().logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func info(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func info(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    // MARK: * Warning
    public class func warning(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public class func warning(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.defaultInstance().logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func warning(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func warning(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    // MARK: * Error
    public class func error(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public class func error(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.defaultInstance().logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func error(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func error(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    // MARK: * Severe
    public class func severe(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.defaultInstance().logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public class func severe(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.defaultInstance().logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func severe(_ closure: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    public func severe(_ functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, closure: @noescape () -> String?) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    // MARK: - Exec Methods
    // MARK: * Verbose
    public class func verboseExec(_ closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.verbose, closure: closure)
    }
    
    public func verboseExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.verbose, closure: closure)
    }
    
    // MARK: * Debug
    public class func debugExec(_ closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.debug, closure: closure)
    }
    
    public func debugExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.debug, closure: closure)
    }
    
    // MARK: * Info
    public class func infoExec(_ closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.info, closure: closure)
    }
    
    public func infoExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.info, closure: closure)
    }
    
    // MARK: * Warning
    public class func warningExec(_ closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.warning, closure: closure)
    }
    
    public func warningExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.warning, closure: closure)
    }
    
    // MARK: * Error
    public class func errorExec(_ closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.error, closure: closure)
    }
    
    public func errorExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.error, closure: closure)
    }
    
    // MARK: * Severe
    public class func severeExec(_ closure: () -> () = {}) {
        self.defaultInstance().exec(XCGLogger.LogLevel.severe, closure: closure)
    }
    
    public func severeExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.LogLevel.severe, closure: closure)
    }
    
    // MARK: - Misc methods
    public func isEnabledForLogLevel (_ logLevel: XCGLogger.LogLevel) -> Bool {
        return logLevel >= self.outputLogLevel
    }
    
    public func logDestination(_ identifier: String) -> XCGLogDestinationProtocol? {
        for logDestination in logDestinations {
            if logDestination.identifier == identifier {
                return logDestination
            }
        }
        
        return nil
    }
    
    @discardableResult
    public func addLogDestination(_ logDestination: XCGLogDestinationProtocol) -> Bool {
        let existingLogDestination: XCGLogDestinationProtocol? = self.logDestination(logDestination.identifier)
        if existingLogDestination != nil {
            return false
        }
        
        logDestinations.append(logDestination)
        return true
    }
    
    public func removeLogDestination(_ logDestination: XCGLogDestinationProtocol) {
        removeLogDestination(logDestination.identifier)
    }
    
    public func removeLogDestination(_ identifier: String) {
        logDestinations = logDestinations.filter({$0.identifier != identifier})
    }
    
    // MARK: - Private methods
    private func _logln(_ logMessage: String, logLevel: LogLevel = .debug) {
        
        var logDetails: XCGLogDetails? = nil
        for logDestination in self.logDestinations {
            if (logDestination.isEnabledForLogLevel(logLevel)) {
                if logDetails == nil {
                    logDetails = XCGLogDetails(logLevel: logLevel, date: Date(), logMessage: logMessage, functionName: "", fileName: "", lineNumber: 0)
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

func extractClassName(_ someObject: Any) -> String {
    return (someObject is Any.Type) ? "\(someObject)" : "\(someObject.dynamicType)"
}
