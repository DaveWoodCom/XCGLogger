//
//  AppDelegate.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Cocoa
import XCGLogger

let log = XCGLogger.sharedInstance()

class AppDelegate: NSObject, NSApplicationDelegate {

    /// #pragma mark - Properties
    @IBOutlet var window: NSWindow

    @IBOutlet var logLevelTextField : NSTextField
    @IBOutlet var currentLogLevelTextField : NSTextField
    @IBOutlet var generateTestLogTextField : NSTextField
    @IBOutlet var logLevelSlider : NSSlider

    /// #pragma mark - Life cycle methods
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application

        // Setup XCGLogger
        let logPath : NSString = "~/Desktop/XCGLogger_Log.txt".stringByExpandingTildeInPath
        log.setup(logLevel: .Debug, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logPath)
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }

    /// #pragma mark - Main View
    @IBAction func verboseButtonTouchUpInside(sender : AnyObject) {
        log.verbose("Verbose button tapped")
    }

    @IBAction func debugButtonTouchUpInside(sender : AnyObject) {
        log.debug("Debug button tapped")
    }

    @IBAction func infoButtonTouchUpInside(sender : AnyObject) {
        log.info("Info button tapped")
    }

    @IBAction func errorButtonTouchUpInside(sender : AnyObject) {
        log.error("Error button tapped")
    }

    @IBAction func severeButtonTouchUpInside(sender : AnyObject) {
        log.severe("Severe button tapped")
    }

    @IBAction func logLevelSliderValueChanged(sender : AnyObject) {
        var logLevel: XCGLogger.LogLevel = .Verbose

        switch(logLevelSlider.floatValue) {
        case 0..1:
            logLevel = .Verbose
        case 1..2:
            logLevel = .Debug
        case 2..3:
            logLevel = .Info
        case 3..4:
            logLevel = .Error
        case 4..5:
            logLevel = .Severe
        default:
            logLevel = .None
        }

        log.outputLogLevel = logLevel
        updateView()
    }

    func updateView() {
        switch (log.outputLogLevel) {
        case .Verbose:
            logLevelSlider.floatValue = 0
            currentLogLevelTextField.stringValue = "Verbose"
        case .Debug:
            logLevelSlider.floatValue = 1
            currentLogLevelTextField.stringValue = "Debug"
        case .Info:
            logLevelSlider.floatValue = 2
            currentLogLevelTextField.stringValue = "Info"
        case .Error:
            logLevelSlider.floatValue = 3
            currentLogLevelTextField.stringValue = "Error"
        case .Severe:
            logLevelSlider.floatValue = 4
            currentLogLevelTextField.stringValue = "Severe"
        case .None:
            logLevelSlider.floatValue = 5
            currentLogLevelTextField.stringValue = "None"
        }
    }
}

