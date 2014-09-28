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

let log = XCGLogger.defaultInstance()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    @IBOutlet var window: NSWindow!

    @IBOutlet var logLevelTextField : NSTextField!
    @IBOutlet var currentLogLevelTextField : NSTextField!
    @IBOutlet var generateTestLogTextField : NSTextField!
    @IBOutlet var logLevelSlider : NSSlider!

    // MARK: - Life cycle methods
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application

        // Setup XCGLogger
        let logPath : NSString = "~/Desktop/XCGLogger_Log.txt".stringByExpandingTildeInPath
        log.setup(logLevel: .Debug, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: logPath)
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }

    // MARK: - Main View
    @IBAction func verboseButtonTouchUpInside(sender : AnyObject) {
        log.verbose("Verbose button tapped")
        log.verboseExec {
            log.verbose("Executed verbose code block")
        }
    }

    @IBAction func debugButtonTouchUpInside(sender : AnyObject) {
        log.debug("Debug button tapped")
        log.debugExec {
            log.debug("Executed debug code block")
        }
    }

    @IBAction func infoButtonTouchUpInside(sender : AnyObject) {
        log.info("Info button tapped")
        log.infoExec {
            log.info("Executed info code block")
        }
    }

    @IBAction func errorButtonTouchUpInside(sender : AnyObject) {
        log.error("Error button tapped")
        log.errorExec {
            log.error("Executed error code block")
        }
    }

    @IBAction func severeButtonTouchUpInside(sender : AnyObject) {
        log.severe("Severe button tapped")
        log.severeExec {
            log.severe("Executed severe code block")
        }
    }

    @IBAction func logLevelSliderValueChanged(sender : AnyObject) {
        var logLevel: XCGLogger.LogLevel = .Verbose

        if (0 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 1) {
            logLevel = .Verbose
        }
        else if (1 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 2) {
            logLevel = .Debug
        }
        else if (2 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 3) {
            logLevel = .Info
        }
        else if (3 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 4) {
            logLevel = .Error
        }
        else if (4 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 5) {
            logLevel = .Severe
        }
        else {
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

