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

    @IBOutlet var logLevelLabel : UILabel
    @IBOutlet var currentLogLevelLabel : UILabel
    @IBOutlet var logLevelSlider : UISlider
    @IBOutlet var generateLabel : UILabel

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        updateView()
    }

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

        switch(logLevelSlider.value) {
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
            logLevelSlider.value = 0
            currentLogLevelLabel.text = "Verbose"
        case .Debug:
            logLevelSlider.value = 1
            currentLogLevelLabel.text = "Debug"
        case .Info:
            logLevelSlider.value = 2
            currentLogLevelLabel.text = "Info"
        case .Error:
            logLevelSlider.value = 3
            currentLogLevelLabel.text = "Error"
        case .Severe:
            logLevelSlider.value = 4
            currentLogLevelLabel.text = "Severe"
        case .None:
            logLevelSlider.value = 5
            currentLogLevelLabel.text = "None"
        }
    }
}

