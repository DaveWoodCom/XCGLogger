//
//  XCGLoggerTests.swift
//  XCGLoggerTests
//
//  Created by Dave Wood on 2014-06-09.
//  Copyright (c) 2014 Cerebral Gardens. All rights reserved.
//

import XCTest
import XCGLogger

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
}
