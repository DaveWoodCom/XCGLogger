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

let appDelegate = NSApplication.shared().delegate as! AppDelegate
let log: XCGLogger = {
    // Setup XCGLogger (Advanced/Recommended Usage)
    // Create a logger object with no destinations
    let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

    // Create a destination for the system console log (via NSLog)
    let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.appleSystemLogDestination")

    // Optionally set some configuration options
    systemDestination.outputLevel = .debug
    systemDestination.showLogIdentifier = false
    systemDestination.showFunctionName = true
    systemDestination.showThreadName = true
    systemDestination.showLevel = true
    systemDestination.showFileName = true
    systemDestination.showLineNumber = true

    // Add colour to the console destination.
    // - Note: You need the XcodeColors Plug-in https://github.com/robbiehanson/XcodeColors installed in Xcode
    // - to see colours in the Xcode console. Plug-ins have been disabled in Xcode 8, so offically you can not see
    // - coloured logs in Xcode 8.
    //let xcodeColorsLogFormatter: XcodeColorsLogFormatter = XcodeColorsLogFormatter()
    //xcodeColorsLogFormatter.colorize(level: .verbose, with: .lightGrey)
    //xcodeColorsLogFormatter.colorize(level: .debug, with: .darkGrey)
    //xcodeColorsLogFormatter.colorize(level: .info, with: .blue)
    //xcodeColorsLogFormatter.colorize(level: .warning, with: .orange)
    //xcodeColorsLogFormatter.colorize(level: .error, with: .red)
    //xcodeColorsLogFormatter.colorize(level: .severe, with: .white, on: .red)
    //systemDestination.formatters = [xcodeColorsLogFormatter]

    // Add the destination to the logger
    log.add(destination: systemDestination)

    // Create a file log destination
    let logPath: String = ("~/Desktop/XCGLogger_Log.txt" as NSString).expandingTildeInPath
    let fileDestination = FileDestination(writeToFile: logPath, identifier: "advancedLogger.fileDestination", shouldAppend: true)

    // Optionally set some configuration options
    fileDestination.outputLevel = .debug
    fileDestination.showLogIdentifier = false
    fileDestination.showFunctionName = true
    fileDestination.showThreadName = true
    fileDestination.showLevel = true
    fileDestination.showFileName = true
    fileDestination.showLineNumber = true
    fileDestination.showDate = true

    // Process this destination in the background
    fileDestination.logQueue = XCGLogger.logQueue

    // Add colour (using the ANSI format) to our file log, you can see the colour when `cat`ing or `tail`ing the file in Terminal on macOS
    let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
    ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
    ansiColorLogFormatter.colorize(level: .debug, with: .black)
    ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
    ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
    ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
    fileDestination.formatters = [ansiColorLogFormatter]

    // Add the destination to the logger
    log.add(destination: fileDestination)

    // Add basic app info, version info etc, to the start of the logs
    log.logAppDetails()
    
    return log
}()

let dateHashFormatter: DateFormatter = {
    let dateHashFormatter = DateFormatter()
    dateHashFormatter.locale = NSLocale.current
    dateHashFormatter.dateFormat = "yyyy-MM-dd_HHmmss_SSS"
    return dateHashFormatter
}()

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties
    @IBOutlet var window: NSWindow!

    @IBOutlet var logLevelTextField: NSTextField!
    @IBOutlet var currentLogLevelTextField: NSTextField!
    @IBOutlet var generateTestLogTextField: NSTextField!
    @IBOutlet var logLevelSlider: NSSlider!

    // MARK: - Life cycle methods
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Insert code here to initialize your application
        updateView()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Main View
    @IBAction func verboseButtonTouchUpInside(_ sender: AnyObject) {
        log.verbose("Verbose button tapped")
        log.verbose {
            // add expensive code required only for logging, then return an optional String
            return "Executed verbose code block" // or nil
        }
    }

    @IBAction func debugButtonTouchUpInside(_ sender: AnyObject) {
        log.debug("Debug button tapped")
        log.debug {
            // add expensive code required only for logging, then return an optional String
            return "Executed debug code block" // or nil
        }
    }

    @IBAction func infoButtonTouchUpInside(_ sender: AnyObject) {
        log.info("Info button tapped")
        log.info {
            // add expensive code required only for logging, then return an optional String
            return "Executed info code block" // or nil
        }
    }

    @IBAction func warningButtonTouchUpInside(_ sender: AnyObject) {
        log.warning("Warning button tapped")
        log.warning {
            // add expensive code required only for logging, then return an optional String
            return "Executed warning code block" // or nil
        }
    }

    @IBAction func errorButtonTouchUpInside(_ sender: AnyObject) {
        log.error("Error button tapped")
        log.error {
            // add expensive code required only for logging, then return an optional String
            return "Executed error code block" // or nil
        }
    }

    @IBAction func severeButtonTouchUpInside(_ sender: AnyObject) {
        log.severe("Severe button tapped")
        log.severe {
            // add expensive code required only for logging, then return an optional String
            return "Executed severe code block" // or nil
        }
    }

    @IBAction func rotateLogFileButtonTouchUpInside(_ sender: AnyObject) {
        if let fileDestination = log.destination(withIdentifier: "advancedLogger.fileDestination") as? FileDestination {

            let dateHash: String = dateHashFormatter.string(from: Date())
            let archiveFilePath: String = ("~/Desktop/XCGLogger_Log_\(dateHash).txt" as NSString).expandingTildeInPath

            fileDestination.rotateFile(to: archiveFilePath)
        }
    }

    @IBAction func logLevelSliderValueChanged(_ sender: AnyObject) {
        var logLevel: XCGLogger.Level = .verbose

        if (0 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 1) {
            logLevel = .verbose
        }
        else if (1 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 2) {
            logLevel = .debug
        }
        else if (2 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 3) {
            logLevel = .info
        }
        else if (3 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 4) {
            logLevel = .warning
        }
        else if (4 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 5) {
            logLevel = .error
        }
        else if (5 <= logLevelSlider.floatValue && logLevelSlider.floatValue < 6) {
            logLevel = .severe
        }
        else {
            logLevel = .none
        }

        log.outputLevel = logLevel
        updateView()
    }

    func updateView() {
        logLevelSlider.floatValue = Float(log.outputLevel.rawValue)
        currentLogLevelTextField.stringValue = "\(log.outputLevel)"
    }
}
