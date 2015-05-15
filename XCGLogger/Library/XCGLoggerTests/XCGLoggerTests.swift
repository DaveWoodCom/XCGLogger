//
//  XCGLoggerTests.swift
//  XCGLoggerTests
//
//  Created by Dave Wood on 2014-06-09.
//  Copyright (c) 2014 Cerebral Gardens. All rights reserved.
//

import XCTest

class XCGLoggerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
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

    func testDefaultInstance() {
        // Test that if we request the default instance multiple times, we always get the same instance
        let defaultInstance1: XCGLogger = XCGLogger.defaultInstance()
        defaultInstance1.identifier = XCGLogger.constants.defaultInstanceIdentifier

        let defaultInstance2: XCGLogger = XCGLogger.defaultInstance()
        defaultInstance2.identifier = XCGLogger.constants.defaultInstanceIdentifier + ".second" // this should also change defaultInstance1.identifier

        XCTAssert(defaultInstance1.identifier == defaultInstance2.identifier, "Fail: defaultInstance() is not returning a common instance")
    }

    func testDistinctInstances() {
        // Test that if we request the multiple instances, we get different instances
        let instance1: XCGLogger = XCGLogger()
        instance1.identifier = "instance1"

        let instance2: XCGLogger = XCGLogger()
        instance2.identifier = "instance2" // this should not affect instance1

        XCTAssert(instance1.identifier != instance2.identifier, "Fail: same instance is being returned")
    }

    func testAddRemoveLogDestination() {
        let testIdentifier = "second.console"

        let log = XCGLogger.defaultInstance()
        let logDestinationCountAtStart = log.logDestinations.count

        let additionalConsoleLogger = XCGConsoleLogDestination(owner: log, identifier: testIdentifier)

        let additionSuccess = log.addLogDestination(additionalConsoleLogger)
        let logDestinationCountAfterAddition = log.logDestinations.count

        log.removeLogDestination(testIdentifier)
        let logDestinationCountAfterRemoval = log.logDestinations.count

        XCTAssert(additionSuccess, "Failed to add additional logger, correct result code")
        XCTAssert(logDestinationCountAtStart == (logDestinationCountAfterAddition - 1), "Failed to add additional logger")
        XCTAssert(logDestinationCountAfterAddition == (logDestinationCountAfterRemoval + 1), "Failed to remove addtional logger")
    }

    func testDenyAdditionOfLogDestinationWithDuplicateIdentifier() {
        let testIdentifier = "second.console"

        let log = XCGLogger.defaultInstance()
        let logDestinationCountAtStart = log.logDestinations.count

        let additionalConsoleLogger = XCGConsoleLogDestination(owner: log, identifier: testIdentifier)
        let additionalConsoleLogger2 = XCGConsoleLogDestination(owner: log, identifier: testIdentifier)

        let additionSuccess = log.addLogDestination(additionalConsoleLogger)
        let logDestinationCountAfterAddition = log.logDestinations.count

        let additionSuccess2 = log.addLogDestination(additionalConsoleLogger2)
        let logDestinationCountAfterAddition2 = log.logDestinations.count

        XCTAssert(additionSuccess, "Failed to add additional logger, correct result code")
        XCTAssert(!additionSuccess2, "Failed to prevent adding additional logger with a duplicate identifier")
        XCTAssert(logDestinationCountAfterAddition == logDestinationCountAfterAddition2, "Failed to prevent adding additional logger with a duplicate identifier")
    }

    func testAvoidStringInterpolationWithAutoclosure() {
        var log: XCGLogger = XCGLogger()
        log.identifier = "com.cerebralgardens.xcglogger.testAvoidStringInterpolationWithAutoclosure"
        log.outputLogLevel = .Debug

        class ObjectWithExpensiveDescription: Printable {
            var descriptionInvoked = false

            var description: String {
                descriptionInvoked = true
                return "expensive"
            }
        }

        let thisObject = ObjectWithExpensiveDescription()

        log.verbose("The description of \(thisObject) is really expensive to create" )
        XCTAssert(!thisObject.descriptionInvoked, "Fail: String was interpolated when it shouldn't have been")
    }

    func testExecExecutes() {
        var log: XCGLogger = XCGLogger()
        log.identifier = "com.cerebralgardens.xcglogger.testExecExecutes"
        log.outputLogLevel = .Debug

        var numberOfTimes: Int = 0
        log.debug {
            ++numberOfTimes
            return "executed closure correctly"
        }

        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 1, "Fail: Didn't execute the closure when it should have")
    }

    func testExecExecutesExactlyOnceWithNilReturnAndMultipleDestinations() {
        var log: XCGLogger = XCGLogger()
        log.setup(logLevel: .Debug, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "/tmp/test.log")
        log.identifier = "com.cerebralgardens.xcglogger.testExecExecutesExactlyOnceWithNilReturnAndMultipleDestinations"
        
        var numberOfTimes: Int = 0
        log.debug {
            ++numberOfTimes
            return nil
        }
        
        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 1, "Fail: Didn't execute the closure exactly once")
    }
    
    func testExecDoesntExecute() {
        var log: XCGLogger = XCGLogger()
        log.identifier = "com.cerebralgardens.xcglogger.testExecDoesntExecute"
        log.outputLogLevel = .Error

        var numberOfTimes: Int = 0
        log.debug {
            ++numberOfTimes
            return "executed closure incorrectly"
        }

        log.outputLogLevel = .Debug
        log.debug("executed: \(numberOfTimes) time(s)")
        XCTAssert(numberOfTimes == 0, "Fail: Executed the closure when it shouldn't have")
    }

    func testMultiThreaded() {
        var log: XCGLogger = XCGLogger()
        log.identifier = "com.cerebralgardens.xcglogger.testMultiThreaded"
        log.setup(logLevel: .Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)

        let linesToLog = ["One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"]
        let myConcurrentQueue = dispatch_queue_create("com.cerebralgardens.xcglogger.testMultiThreaded.queue", DISPATCH_QUEUE_CONCURRENT)
        dispatch_apply(linesToLog.count, myConcurrentQueue) { (index: Int) in
            log.debug(linesToLog[Int(index)])
        }
    }
    
    func testDateFormatterIsCached() {
        var log: XCGLogger = XCGLogger()
        log.identifier = "com.cerebralgardens.xcglogger.testDateFormatterIsCached"
        
        let dateFormatter1 = log.dateFormatter
        let dateFormatter2 = log.dateFormatter
        
        XCTAssert(dateFormatter1 === dateFormatter2, "Fail: Received two different date formatter objects")
    }
    
    func testCustomDateFormatter() {
        var log: XCGLogger = XCGLogger()
        log.identifier = "com.cerebralgardens.xcglogger.testCustomDateFormatter"
        log.outputLogLevel = .Debug
        
        let defaultDateFormatter = log.dateFormatter
        
        let dateFormat = "MM/dd/yyyy hh:mma"

        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = dateFormat

        log.dateFormatter = dateFormatter
        
        log.debug("Test date format is different than our default")
        
        XCTAssertNotNil(log.dateFormatter, "Fail: date formatter is nil")
        XCTAssertEqual(log.dateFormatter!.dateFormat, dateFormat, "Fail: date format doesn't match our custom date format")
        XCTAssert(defaultDateFormatter != dateFormatter, "Fail: Did not assign a custom date formatter")
    }
}
