//
//  XCGLoggerTests.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-09.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
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
        return "\(XCGLogger.Constants.baseIdentifier).\(functionName)"
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

    /// Test our default instance starts with the correct default destinations
    func test_00022_DefaultInstanceDestinations() {
        let defaultInstance: XCGLogger = XCGLogger.default

        let consoleDestination: ConsoleDestination? = defaultInstance.destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination

        XCTAssert(consoleDestination != nil, "Fail: default console destination not attached to our default instance")
        XCTAssert(defaultInstance.destinations.count == 1, "Fail: Incorrect number of destinations on our default instance")
    }

    /// Test that we can add additonal destinations
    func test_00030_addDestination() {
        let log = XCGLogger(identifier: functionIdentifier())
        let destinationCountAtStart = log.destinations.count

        let additionalConsoleLogger = ConsoleDestination(owner: log, identifier: log.identifier + ".second.console")

        let additionSuccess = log.add(destination: additionalConsoleLogger)
        let destinationCountAfterAddition = log.destinations.count

        XCTAssert(additionSuccess, "Failed to add additional destination")
        XCTAssert(destinationCountAtStart == (destinationCountAfterAddition - 1), "Failed to add additional destination")
    }

    /// Test we can remove existing destinations
    func test_00040_RemoveDestination() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let destinationCountAtStart = log.destinations.count

        log.remove(destinationWithIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier)
        let destinationCountAfterRemoval = log.destinations.count

        XCTAssert(destinationCountAtStart == (destinationCountAfterRemoval + 1), "Failed to remove destination")
    }

    /// Test that we can not add a destination with a duplicate identifier
    func test_00050_DenyAdditionOfDestinationWithDuplicateIdentifier() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testIdentifier = log.identifier + ".testIdentifier"
        let additionalConsoleLogger = ConsoleDestination(owner: log, identifier: testIdentifier)
        let additionalConsoleLogger2 = ConsoleDestination(owner: log, identifier: testIdentifier)

        let additionSuccess = log.add(destination: additionalConsoleLogger)
        let destinationCountAfterAddition = log.destinations.count

        let additionSuccess2 = log.add(destination: additionalConsoleLogger2)
        let destinationCountAfterAddition2 = log.destinations.count

        XCTAssert(additionSuccess, "Failed to add additional destination")
        XCTAssert(!additionSuccess2, "Failed to prevent adding additional destination with a duplicate identifier")
        XCTAssert(destinationCountAfterAddition == destinationCountAfterAddition2, "Failed to prevent adding additional destination with a duplicate identifier")
    }

    /// Test that closures for a log aren't executed via string interpolation if they aren't needed
    func test_00060_AvoidStringInterpolationWithAutoclosure() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

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
        log.outputLevel = .debug

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
        log.setup(level: .debug, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "/tmp/test.log")

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
        log.outputLevel = .error

        var numberOfTimes: Int = 0
        log.debug {
            numberOfTimes += 1
            return "executed closure incorrectly"
        }

        log.outputLevel = .debug
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
        log.outputLevel = .debug

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
        let testDestination: TestDestination = TestDestination(owner: log, identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = true
        log.add(destination: testDestination)

        // We force the date for this part of the test to ensure a change of date as the test runs doesn't break the test
        let knownDate = Date(timeIntervalSince1970: 0)
        let message = "Testing date format output matches what we expect"
        testDestination.add(expectedLogMessage: "\(alternateDateFormatter.string(from: knownDate)) [\(XCGLogger.Level.debug)] [\(filename)] \(#function) > \(message)")

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")

        let knownLogDetails = LogDetails(level: .debug, date: knownDate, message: message, functionName: #function, fileName: #file, lineNumber: #line)
        testDestination.process(logDetails: knownLogDetails)

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test that we can log a variety of different object types
    func test_00120_VariousParameters() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(level: .verbose, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testDestination: TestDestination = TestDestination(owner: log, identifier: log.identifier + ".testDestination")
        testDestination.outputLevel = .verbose
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.info)] [\(filename)] \(#function) > testVariousParameters starting")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.info("testVariousParameters starting")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.verbose)] [\(filename)] \(#function) > ")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.verbose()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        // Should not log anything, so there are no expected log messages
        log.verbose { return nil }
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(filename)] \(#function) > 1.2")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug(1.2)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.info)] [\(filename)] \(#function) > true")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.info(true)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.warning)] [\(filename)] \(#function) > [\"a\", \"b\", \"c\"]")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.warning(["a", "b", "c"])
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let knownDate = Date(timeIntervalSince1970: 0)
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.error)] [\(filename)] \(#function) > \(knownDate)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.error { return knownDate }
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let optionalString: String? = "text"
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.severe)] [\(filename)] \(#function) > \(optionalString ?? "")")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.severe(optionalString)
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test our noMessageClosure works as expected
    func test_00130_NoMessageClosure() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let testDestination: TestDestination = TestDestination(owner: log, identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let checkDefault = String(describing: log.noMessageClosure() ?? "__unexpected__")
        XCTAssert(checkDefault == "", "Fail: Default noMessageClosure doesn't return expected value")

        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(filename)] \(#function) > ")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        log.noMessageClosure = { return "***" }
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(filename)] \(#function) > ***")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        let knownDate = Date(timeIntervalSince1970: 0)
        log.noMessageClosure = { return knownDate }
        testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(filename)] \(#function) > \(knownDate)")
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 1, "Fail: Didn't correctly load all of the expected log messages")
        log.debug()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")

        log.noMessageClosure = { return nil }
        // Should not log anything, so there are no expected log messages
        log.debug()
        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
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

    func test_00150_ExtractTypeName() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.outputLevel = .debug

        let className: String = extractTypeName(log)
        let stringName: String = extractTypeName(className)
        let intName: String = extractTypeName(4)

        let optionalString: String? = nil
        let optionalName: String = extractTypeName(optionalString)

        log.debug("className: \(className)")
        log.debug("stringName: \(stringName)")
        log.debug("intName: \(intName)")
        log.debug("optionalName: \(optionalName)")

        XCTAssert(className == "XCGLogger", "Fail: Didn't extract the correct class name")
        XCTAssert(stringName == "String", "Fail: Didn't extract the correct class name")
        XCTAssert(intName == "Int", "Fail: Didn't extract the correct class name")
        XCTAssert(optionalName == "Optional<String>", "Fail: Didn't extract the correct class name")
    }

    /// Test logging works correctly when logs are generated from multiple threads
    func test_01010_MultiThreaded() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testDestination: TestDestination = TestDestination(owner: log, identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        testDestination.logQueue = DispatchQueue(label: log.identifier + ".serialQueue")
        log.add(destination: testDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(filename)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        let myConcurrentQueue = DispatchQueue(label: log.identifier + ".concurrentQueue", attributes: .concurrent)
        // TODO: Switch to DispatchQueue.apply() when/if it is implemented in Swift 3.0
        // see: SE-0088 - https://github.com/apple/swift-evolution/blob/7fcba970b88a5de3d302d291dc7bc9dfba0f9399/proposals/0088-libdispatch-for-swift3.md
        // myConcurrentQueue.apply(linesToLog.count) { (index: Int) in
        __dispatch_apply(linesToLog.count, myConcurrentQueue, { (index: Int) -> () in
            log.debug(linesToLog[index])
        })

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test logging with closures works correctly when generated from multiple threads
    func test_01020_MultiThreaded2() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier())
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let testDestination: TestDestination = TestDestination(owner: log, identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        testDestination.logQueue = DispatchQueue(label: log.identifier + ".serialQueue")
        log.add(destination: testDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(filename)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        let myConcurrentQueue = DispatchQueue(label: log.identifier + ".concurrentQueue", attributes: .concurrent)
        // TODO: Switch to DispatchQueue.apply() when/if it is implemented in Swift 3.0
        // see: SE-0088 - https://github.com/apple/swift-evolution/blob/7fcba970b88a5de3d302d291dc7bc9dfba0f9399/proposals/0088-libdispatch-for-swift3.md
        // myConcurrentQueue.apply(linesToLog.count) { (index: Int) in
        __dispatch_apply(linesToLog.count, myConcurrentQueue, { (index: Int) -> () in
            log.debug {
                return "\(linesToLog[index])"
            }
        })

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    /// Test that our background processing works
    func test_01030_BackgroundLogging() {
        let log: XCGLogger = XCGLogger(identifier: functionIdentifier(), includeDefaultDestinations: false)

        let systemDestination = AppleSystemLogDestination(owner: log, identifier: log.identifier + ".systemDestination")
        systemDestination.outputLevel = .debug
        systemDestination.showThreadName = true

        // Note: The thread name included in the log message should be "main" even though the log is processed in a background thread. This is because
        // it uses the thread name of the thread the log function is called in, not the thread used to do the output.
        systemDestination.logQueue = DispatchQueue.global(qos: .background)
        log.add(destination: systemDestination)

        let testDestination: TestDestination = TestDestination(owner: log, identifier: log.identifier + ".testDestination")
        testDestination.showThreadName = false
        testDestination.showLevel = true
        testDestination.showFileName = true
        testDestination.showLineNumber = false
        testDestination.showDate = false
        log.add(destination: testDestination)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        for lineToLog in linesToLog {
            testDestination.add(expectedLogMessage: "[\(XCGLogger.Level.debug)] [\(filename)] \(#function) > \(lineToLog)")
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == linesToLog.count, "Fail: Didn't correctly load all of the expected log messages")

        for line in linesToLog {
            log.debug(line)
        }

        XCTAssert(testDestination.remainingNumberOfExpectedLogMessages == 0, "Fail: Didn't receive all expected log lines")
        XCTAssert(testDestination.numberOfUnexpectedLogMessages == 0, "Fail: Received an unexpected log line")
    }

    func test_99999_LastTest() {
        // Add a final test that just waits a second, so any tests using the background can finish outputting results
        Thread.sleep(forTimeInterval: 1.0)
    }
}

