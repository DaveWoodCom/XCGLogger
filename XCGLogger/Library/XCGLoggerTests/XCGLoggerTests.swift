//
//  XCGLoggerTests.swift
//  XCGLoggerTests
//
//  Created by Dave Wood on 2014-06-09.
//  Copyright (c) 2014 Cerebral Gardens. All rights reserved.
//

import XCTest
@testable import XCGLogger

/// Tests
class XCGLoggerTests: XCTestCase {
    /// This file's filename for use in testing expected log messages
    let filename = { return (#file as NSString).lastPathComponent }()

    /// Calculate a base identifier to use for the giving function name.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///
    /// - Returns:  A string to use as the base identifier for objects in the test
    ///
    func functionIdentifier(_ functionName: StaticString = #function) -> String {
        return "com.cerebralgardens.xcglogger.\(functionName)"
    }

    /// Set up prior to each test
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    /// Tear down after each test
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //    func testExample() {
    //        // This is an example of a functional test case.
    //        XCTAssert(true, "Pass")
    //    }
    //
    //    func testPerformanceExample() {
    //        // This is an example of a performance test case.
    //        self.measureBlock() {
    //            // Put the code you want to measure the time of here.
    //        }
    //    }

    /// Test that if we request the default instance multiple times, we always get the same instance
    func test_00010_DefaultInstance() {
        let defaultInstance1: XCGLogger = XCGLogger.default
        let defaultInstance2: XCGLogger = XCGLogger.default

        XCTAssert(defaultInstance1 === defaultInstance2, "Fail: default is not returning a common instance")
    }

    /// Test that if we request the multiple instances, we get different instances
    func test_00020_DistinctInstances() {
        let instance1: XCGLogger = XCGLogger()
        instance1.identifier = "instance1"

        let instance2: XCGLogger = XCGLogger()
        instance2.identifier = "instance2" // this should not affect instance1

        XCTAssert(instance1.identifier != instance2.identifier, "Fail: same instance is being returned")
    }

    /// Test that we can add additonal log destinations
    func test_00030_addLogDestination() {
        let log = XCGLogger(identifier: functionIdentifier())
        let logDestinationCountAtStart = log.logDestinations.count

        let additionalConsoleLogger = XCGConsoleLogDestination(owner: log, identifier: log.identifier + ".second.console")

        let additionSuccess = log.add(logDestination: additionalConsoleLogger)
        let logDestinationCountAfterAddition = log.logDestinations.count

        XCTAssert(additionSuccess, "Failed to add additional log destination")
        XCTAssert(logDestinationCountAtStart == (logDestinationCountAfterAddition - 1), "Failed to add additional log destination")
    }

    /// Test we can remove existing log destinations
    func test_00040_RemoveLogDestination() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLogLevel = .debug

        let logDestinationCountAtStart = log.logDestinations.count

        log.remove(logDestinationWithIdentifier: XCGLogger.Constants.baseConsoleLogDestinationIdentifier)
        let logDestinationCountAfterRemoval = log.logDestinations.count

        XCTAssert(logDestinationCountAtStart == (logDestinationCountAfterRemoval + 1), "Failed to remove log destination")
    }

    /// Test that we can not add a log destination with a duplicate identifier
    func test_00050_DenyAdditionOfLogDestinationWithDuplicateIdentifier() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLogLevel = .debug

        let testIdentifier = log.identifier + ".testIdentifier"
        let additionalConsoleLogger = XCGConsoleLogDestination(owner: log, identifier: testIdentifier)
        let additionalConsoleLogger2 = XCGConsoleLogDestination(owner: log, identifier: testIdentifier)

        let additionSuccess = log.add(logDestination: additionalConsoleLogger)
        let logDestinationCountAfterAddition = log.logDestinations.count

        let additionSuccess2 = log.add(logDestination: additionalConsoleLogger2)
        let logDestinationCountAfterAddition2 = log.logDestinations.count

        XCTAssert(additionSuccess, "Failed to add additional log destination")
        XCTAssert(!additionSuccess2, "Failed to prevent adding additional log destination with a duplicate identifier")
        XCTAssert(logDestinationCountAfterAddition == logDestinationCountAfterAddition2, "Failed to prevent adding additional log destination with a duplicate identifier")
    }

    /// Test that closures for a log aren't executed via string interpolation if they aren't needed
    func test_00060_AvoidStringInterpolationWithAutoclosure() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLogLevel = .debug

        class ObjectWithExpensiveDescription: CustomStringConvertible {
            var descriptionInvoked = false

            var description: String {
                descriptionInvoked = true
                return "expensive"
            }
        }

        let thisObject = ObjectWithExpensiveDescription()

        log.verbose("The description of \(thisObject) is really expensive to create")
        XCTAssert(!thisObject.descriptionInvoked, "Fail: String was interpolated when it shouldn't have been")
    }

    /// Test that closures for a log execute when required
    func test_00070_ExecExecutes() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLogLevel = .debug

        var numberOfTimes: Int = 0
        log.debug {
            numberOfTimes += 1
            return "executed closure correctly"
        }

        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 1, "Fail: Didn't execute the closure when it should have")
    }

    /// Test that closures execute exactly once, even when being logged to multiple destinations, and even if they return nil
    func test_00080_ExecExecutesExactlyOnceWithNilReturnAndMultipleDestinations() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(logLevel: .debug, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "/tmp/test.log")

        var numberOfTimes: Int = 0
        log.debug {
            numberOfTimes += 1
            return nil
        }

        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 1, "Fail: Didn't execute the closure exactly once")
    }

    /// Test that closures for a log aren't executed if they aren't needed
    func test_00090_ExecDoesntExecute() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLogLevel = .error

        var numberOfTimes: Int = 0
        log.debug {
            numberOfTimes += 1
            return "executed closure incorrectly"
        }

        log.outputLogLevel = .debug
        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 0, "Fail: Didn't execute the closure when it should have")
    }

    /// Test that we correctly cache date formatter objects, and don't create new ones each time
    func test_00100_DateFormatterIsCached() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())

        let dateFormatter1 = log.dateFormatter
        let dateFormatter2 = log.dateFormatter

        XCTAssert(dateFormatter1 === dateFormatter2, "Fail: Received two different date formatter objects")
    }

    /// Test our custom date formatter works
    func test_00110_CustomDateFormatter() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLogLevel = .debug

        let defaultDateFormatter = log.dateFormatter
        let alternateDateFormat = "MM/dd/yyyy h:mma"
        let alternateDateFormatter = DateFormatter()
        alternateDateFormatter.dateFormat = alternateDateFormat

        log.dateFormatter = alternateDateFormatter

        log.debug("Test date format is different than our default")

        XCTAssertNotNil(log.dateFormatter, "Fail: date formatter is nil")
        XCTAssertEqual(log.dateFormatter!.dateFormat, alternateDateFormat, "Fail: date format doesn't match our custom date format")
        XCTAssert(defaultDateFormatter != alternateDateFormatter, "Fail: Did not assign a custom date formatter")

        // We add this destination after the normal log.debug() call above (that's for humans to look at), because
        // there's a chance when the test runs, that we could cross time boundaries (ie, second [or even the year])
        let testLogDestination: XCGTestLogDestination = XCGTestLogDestination(owner: log, identifier: log.identifier + ".testLogDestination")
        testLogDestination.showThreadName = false
        testLogDestination.showLogLevel = true
        testLogDestination.showFileName = true
        testLogDestination.showLineNumber = false
        testLogDestination.showDate = true
        log.add(logDestination: testLogDestination)

        // We force the date for this part of the test to ensure a change of date as the test runs doesn't break the test
        let knownDate = Date(timeIntervalSince1970: 0)
        let message = "Testing date format output matches what we expect"
        testLogDestination.add(expectedLogMessage: "\(alternateDateFormatter.string(from: knownDate)) [\(XCGLogger.LogLevel.debug)] [\(filename)] \(#function) > \(message)")

        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")

        let knownLogDetails = XCGLogDetails(logLevel: .debug, date: knownDate, logMessage: message, functionName: #function, fileName: #file, lineNumber: #line)
        testLogDestination.process(logDetails: knownLogDetails)

        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test that we can log a variety of different object types
    func test_00120_VariousParameters() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(logLevel: .verbose, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testLogDestination: XCGTestLogDestination = XCGTestLogDestination(owner: log, identifier: log.identifier + ".testLogDestination")
        testLogDestination.outputLogLevel = .verbose
        testLogDestination.showThreadName = false
        testLogDestination.showLogLevel = true
        testLogDestination.showFileName = true
        testLogDestination.showLineNumber = false
        testLogDestination.showDate = false
        log.add(logDestination: testLogDestination)

        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.info)] [\(filename)] \(#function) > testVariousParameters starting")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.info("testVariousParameters starting")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.verbose)] [\(filename)] \(#function) > ")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.verbose()
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        // Should not log anything, so there are no expected log messages
        log.verbose { return nil }
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.debug)] [\(filename)] \(#function) > 1.2")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(1.2)
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.info)] [\(filename)] \(#function) > true")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.info(true)
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.warning)] [\(filename)] \(#function) > [\"a\", \"b\", \"c\"]")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.warning(["a", "b", "c"])
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let knownDate = Date(timeIntervalSince1970: 0)
        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.error)] [\(filename)] \(#function) > \(knownDate)")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.error { return knownDate }
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let optionalString: String? = "text"
        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.severe)] [\(filename)] \(#function) > \(optionalString ?? "")")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.severe(optionalString)
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test our noMessageClosure works as expected
    func test_00130_NoMessageClosure() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLogLevel = .debug

        let testLogDestination: XCGTestLogDestination = XCGTestLogDestination(owner: log, identifier: log.identifier + ".testLogDestination")
        testLogDestination.showThreadName = false
        testLogDestination.showLogLevel = true
        testLogDestination.showFileName = true
        testLogDestination.showLineNumber = false
        testLogDestination.showDate = false
        log.add(logDestination: testLogDestination)

        let checkDefault = String(describing: log.noMessageClosure() ?? "__unexpected__")
        XCTAssert(checkDefault == "", "Fail: Default noMessageClosure doesn't return expected value")

        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.debug)] [\(filename)] \(#function) > ")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        log.noMessageClosure = { return "***" }
        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.debug)] [\(filename)] \(#function) > ***")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let knownDate = Date(timeIntervalSince1970: 0)
        log.noMessageClosure = { return knownDate }
        testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.debug)] [\(filename)] \(#function) > \(knownDate)")
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        log.noMessageClosure = { return nil }
        // Should not log anything, so there are no expected log messages
        log.debug()
        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    func test_00140_QueueName() {
        let logQueue = DispatchQueue(label: functionIdentifier() + ".serialQueue.😆")

        let labelDirectlyRead: String = logQueue.label
        var labelExtracted: String? = nil

        logQueue.sync {
            labelExtracted = DispatchQueue.currentQueueLabel
        }

        XCTAssert(labelExtracted != nil, "Fail: Didn't get a label for the current queue")

        print("labelDirectlyRead: `\(labelDirectlyRead)`")
        print("labelExtracted: `\(labelExtracted!)`")

        XCTAssert(labelDirectlyRead == labelExtracted!, "Fail: Didn't get the correct queue label")
    }

    /// Test logging works correctly when logs are generated from multiple threads
    func test_01010_MultiThreaded() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(logLevel: .debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testLogDestination: XCGTestLogDestination = XCGTestLogDestination(owner: log, identifier: log.identifier + ".testLogDestination")
        testLogDestination.showThreadName = false
        testLogDestination.showLogLevel = true
        testLogDestination.showFileName = true
        testLogDestination.showLineNumber = false
        testLogDestination.showDate = false
        testLogDestination.logQueue = DispatchQueue(label: log.identifier + ".serialQueue")
        log.add(logDestination: testLogDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.debug)] [\(filename)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        let myConcurrentQueue = DispatchQueue(label: log.identifier + ".concurrentQueue", attributes: .concurrent)
        // TODO: Switch to DispatchQueue.apply() when/if it is implemented in Swift 3.0
        // see: SE-0088 - https://github.com/apple/swift-evolution/blob/7fcba970b88a5de3d302d291dc7bc9dfba0f9399/proposals/0088-libdispatch-for-swift3.md
        // myConcurrentQueue.apply(linesToLog.count) { (index: Int) in
        __dispatch_apply(linesToLog.count, myConcurrentQueue, { (index: Int) -> () in
            log.debug(linesToLog[index])
        })

        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test logging with closures works correctly when generated from multiple threads
    func test_01020_MultiThreaded2() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(logLevel: .debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testLogDestination: XCGTestLogDestination = XCGTestLogDestination(owner: log, identifier: log.identifier + ".testLogDestination")
        testLogDestination.showThreadName = false
        testLogDestination.showLogLevel = true
        testLogDestination.showFileName = true
        testLogDestination.showLineNumber = false
        testLogDestination.showDate = false
        testLogDestination.logQueue = DispatchQueue(label: log.identifier + ".serialQueue")
        log.add(logDestination: testLogDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.debug)] [\(filename)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        let myConcurrentQueue = DispatchQueue(label: log.identifier + ".concurrentQueue", attributes: .concurrent)
        // TODO: Switch to DispatchQueue.apply() when/if it is implemented in Swift 3.0
        // see: SE-0088 - https://github.com/apple/swift-evolution/blob/7fcba970b88a5de3d302d291dc7bc9dfba0f9399/proposals/0088-libdispatch-for-swift3.md
        // myConcurrentQueue.apply(linesToLog.count) { (index: Int) in
        __dispatch_apply(linesToLog.count, myConcurrentQueue, { (index: Int) -> () in
            log.debug {
                return "\(linesToLog[index])"
            }
        })

        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test that our background processing works
    func test_01030_BackgroundLogging() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier(), includeDefaultDestinations: false)

        let systemLogDestination = XCGNSLogDestination(owner: log, identifier: log.identifier + ".systemLogDestination")
        systemLogDestination.outputLogLevel = .debug
        systemLogDestination.showThreadName = true

        // Note: The thread name included in the log message should be "main" even though the log is processed in a background thread. This is because
        // it uses the thread name of the thread the log function is called in, not the thread used to do the output.
        systemLogDestination.logQueue = DispatchQueue.global(qos: .background)
        log.add(logDestination: systemLogDestination)

        let testLogDestination: XCGTestLogDestination = XCGTestLogDestination(owner: log, identifier: log.identifier + ".testLogDestination")
        testLogDestination.showThreadName = false
        testLogDestination.showLogLevel = true
        testLogDestination.showFileName = true
        testLogDestination.showLineNumber = false
        testLogDestination.showDate = false
        log.add(logDestination: testLogDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testLogDestination.add(expectedLogMessage: "[\(XCGLogger.LogLevel.debug)] [\(filename)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        for line in linesToLog {
            log.debug(line)
        }

        XCTAssert(testLogDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testLogDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    func test_99999_LastTest() {
        // Add a final test that just waits a second, so any tests using the background can finish outputting results
        Thread.sleep(forTimeInterval: 1.0)
    }
}

// MARK: - XCGTestLogDestination
/// A log destination for testing, preload it with the expected logs, send your logs, then check for success
open class XCGTestLogDestination: XCGBaseLogDestination {
    // MARK: - Properties
    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil

    /// Array of all expected log messages
    open var expectedLogMessages: [String] = []

    /// Array of received, unexpected log messages
    open var unexpectedLogMessages: [String] = []

    /// Number of log messages still expected
    open var remainingNumberOfExpectedLogMessages: Int {
        get {
            return expectedLogMessages.count
        }
    }

    /// Number of unexpected log messages
    open var numberOfUnexpectedLogMessages: Int {
        get {
            return unexpectedLogMessages.count
        }
    }

    /// Add the messages you expect to be logged
    ///
    /// - Parameters:
    ///     - expectedLogMessage:   The log message, formated as you expect it to be received.
    ///
    /// - Returns:  Nothing
    ///
    open func add(expectedLogMessage logMessage: String) {
        sync {
            expectedLogMessages.append(logMessage)
        }
    }

    /// Execute a closure on the logQueue if it exists, otherwise just execute on the current thread
    ///
    /// - Parameters:
    ///     - closure:  The closure to execute.
    ///
    /// - Returns:  Nothing
    ///
    fileprivate func sync(closure: () -> ()) {
        if let logQueue = logQueue {
            logQueue.sync {
                closure()
            }
        }
        else {
            closure()
        }
    }

    // MARK: - Overridden Methods
    /// Removes line from expected log messages if there's a match, otherwise adds to unexpected log messages.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - logMessage:   Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: XCGLogDetails, logMessage: String) {
        sync {
            let index = expectedLogMessages.index(of: logMessage)
            if let index = index {
                expectedLogMessages.remove(at: index)
            }
            else {
                unexpectedLogMessages.append(logMessage)
            }
        }
    }
}
