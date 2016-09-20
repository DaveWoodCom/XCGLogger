//
//  InterfaceController.swift
//  watchOSDemo Extension
//
//  Created by Dave Wood on 2015-09-09.
//  Copyright © 2015 Cerebral Gardens. All rights reserved.
//

import WatchKit
import Foundation
import XCGLogger

let log: XCGLogger = {
    // Setup XCGLogger
    let log = XCGLogger.default
    #if USE_NSLOG // Set via Build Settings, under Other Swift Flags
        log.remove(destinationWithIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier)
        log.add(destination: AppleSystemLogDestination(identifier: XCGLogger.Constants.systemLogDestinationIdentifier))
        log.logAppDetails()
    #else
        log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)

        // Add colour to the console destination.
        // - Note: You need the XcodeColors Plug-in https://github.com/robbiehanson/XcodeColors installed in Xcode
        // - to see colours in the Xcode console. Plug-ins have been disabled in Xcode 8, so offically you can not see
        // - coloured logs in Xcode 8.
        //if let consoleDestination: ConsoleDestination = log.destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination {
        //    let xcodeColorsLogFormatter: XcodeColorsLogFormatter = XcodeColorsLogFormatter()
        //    xcodeColorsLogFormatter.colorize(level: .verbose, with: .lightGrey)
        //    xcodeColorsLogFormatter.colorize(level: .debug, with: .darkGrey)
        //    xcodeColorsLogFormatter.colorize(level: .info, with: .blue)
        //    xcodeColorsLogFormatter.colorize(level: .warning, with: .orange)
        //    xcodeColorsLogFormatter.colorize(level: .error, with: .red)
        //    xcodeColorsLogFormatter.colorize(level: .severe, with: .white, on: .red)
        //    consoleDestination.formatters = [xcodeColorsLogFormatter]
        //}
    #endif
    
    return log
}()

class InterfaceController: WKInterfaceController {

    override func awake(withContext context: Any?) {
        // Display initial app info
        _ = log

        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func verboseButtonTapped(_ sender: WKInterfaceButton) {
        log.verbose("Verbose tapped on the Watch")
    }

    @IBAction func debugButtonTapped(_ sender: WKInterfaceButton) {
        log.debug("Debug tapped on the Watch")
    }

    @IBAction func infoButtonTapped(_ sender: WKInterfaceButton) {
        log.info("Info tapped on the Watch")
    }

    @IBAction func warningButtonTapped(_ sender: WKInterfaceButton) {
        log.warning("Warning tapped on the Watch")
    }

    @IBAction func errorButtonTapped(_ sender: WKInterfaceButton) {
        log.error("Error tapped on the Watch")
    }

    @IBAction func severeButtonTapped(_ sender: WKInterfaceButton) {
        log.severe("Severe tapped on the Watch")
    }
}
