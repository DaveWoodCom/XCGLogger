//
//  ViewController.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright (c) 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import UIKit
import XCGLogger

class ViewController: UIViewController {

    @IBOutlet var logLevelLabel: UILabel!
    @IBOutlet var currentLogLevelLabel: UILabel!
    @IBOutlet var logLevelSlider: UISlider!
    @IBOutlet var generateLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        updateView()
    }

    @IBAction func verboseButtonTouchUpInside(_ sender: AnyObject) {
        log.verbose("Verbose button tapped")
        log.verbose {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed verbose code block" // or nil
        }
    }

    @IBAction func debugButtonTouchUpInside(_ sender: AnyObject) {
        log.debug("Debug button tapped")
        log.debug {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed debug code block" // or nil
        }
    }

    @IBAction func infoButtonTouchUpInside(_ sender: AnyObject) {
        log.info("Info button tapped")
        log.info {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed info code block" // or nil
        }
    }

    @IBAction func warningButtonTouchUpInside(_ sender: AnyObject) {
        log.warning("Warning button tapped")
        log.warning {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed warning code block" // or nil
        }
    }

    @IBAction func errorButtonTouchUpInside(_ sender: AnyObject) {
        log.error("Error button tapped")
        log.error {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed error code block" // or nil
        }
    }

    @IBAction func severeButtonTouchUpInside(_ sender: AnyObject) {
        log.severe("Severe button tapped")
        log.severe {
            // add expensive code required only for logging, then return an optional String
            noop()
            return "Executed severe code block" // or nil
        }
    }

    @IBAction func logLevelSliderValueChanged(_ sender: AnyObject) {
        var logLevel: XCGLogger.LogLevel = .verbose

        if (0 <= logLevelSlider.value && logLevelSlider.value < 1) {
            logLevel = .verbose
        }
        else if (1 <= logLevelSlider.value && logLevelSlider.value < 2) {
            logLevel = .debug
        }
        else if (2 <= logLevelSlider.value && logLevelSlider.value < 3) {
            logLevel = .info
        }
        else if (3 <= logLevelSlider.value && logLevelSlider.value < 4) {
            logLevel = .warning
        }
        else if (4 <= logLevelSlider.value && logLevelSlider.value < 5) {
            logLevel = .error
        }
        else if (5 <= logLevelSlider.value && logLevelSlider.value < 6) {
            logLevel = .severe
        }
        else {
            logLevel = .none
        }

        log.outputLogLevel = logLevel
        updateView()
    }

    func updateView() {
        logLevelSlider.value = Float(log.outputLogLevel.rawValue)
        currentLogLevelLabel.text = "\(log.outputLogLevel)"
    }
}
