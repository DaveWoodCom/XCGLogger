#XCGLogger

[![Swift 2.3](https://img.shields.io/badge/Swift-2.3-orange.svg?style=flat)](https://swift.org/)
[![Platforms OS X | iOS | tvOS | watchOS](https://img.shields.io/badge/Platforms-OS%20X%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgray.svg?style=flat)](https://swift.org/)
[![License MIT](https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat)](https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt)

[![Travis CI](https://img.shields.io/travis/DaveWoodCom/XCGLogger/swift_2.3.svg?style=flat)](https://travis-ci.org/DaveWoodCom/XCGLogger)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Version](https://img.shields.io/cocoapods/v/XCGLogger.svg?style=flat)](https://cocoapods.org/pods/XCGLogger)

[![Sponsors](https://img.shields.io/badge/Sponsors-Cerebral%20Gardens-orange.svg?style=flat)](https://www.cerebralgardens.com/)
[![Twitter @DaveWoodX](https://img.shields.io/twitter/follow/DaveWoodX.svg?style=social)](https://twitter.com/DaveWoodX)

##tl;dr
XCGLogger is the original debug log module for use in Swift projects. 

Swift does not include a C preprocessor so developers are unable to use the debug log `#define` macros they would use in Objective-C. This means our traditional way of generating nice debug logs no longer works. Resorting to just plain old `print` calls means you lose a lot of helpful information, or requires you to type a lot more code.

XCGLogger allows you to log details to the console (and optionally a file, or other custom destinations), just like you would have with `NSLog()` or `print()`, but with additional information, such as the date, function name, filename and line number.

Go from this:

```Simple message```

to this:

```2014-06-09 06:44:43.600 [Debug] [AppDelegate.swift:40] application(_:didFinishLaunchingWithOptions:): Simple message```

#####Example
<img src="https://raw.githubusercontent.com/DaveWoodCom/XCGLogger/master/ReadMeImages/SampleLog.png" alt="Example" style="width: 690px;" />

###Communication _(Hat Tip AlamoFire)_

* If you need help, use [Stack Overflow](http://stackoverflow.com/questions/tagged/xcglogger) (Tag '[xcglogger](http://stackoverflow.com/questions/tagged/xcglogger)').
* If you'd like to ask a general question, use [Stack Overflow](http://stackoverflow.com/questions/tagged/xcglogger).
* If you've found a bug, open an issue.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request.
* If you use XCGLogger, please Star the project on [GitHub](https://github.com/DaveWoodCom/XCGLogger)

##Installation

###Git Submodule

Execute:

```git submodule add https://github.com/DaveWoodCom/XCGLogger.git```
	
in your repository folder.

###[Carthage](https://github.com/Carthage/Carthage)

Add the following line to your `Cartfile`.

```github "DaveWoodCom/XCGLogger" ~> 3.6.0```

Then run `carthage update --no-use-binaries` or just `carthage update`. For details of the installation and usage of Carthage, visit [it's project page](https://github.com/Carthage/Carthage).

###[CocoaPods](https://cocoapods.org/)

Add the following lines to your `Podfile`.

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'XCGLogger', '~> 3.6.0'
```

Then run `pod install`. For details of the installation and usage of CocoaPods, visit [it's official web site](https://cocoapods.org/).

###Backwards Compatibility

Use:
* XCGLogger version [4.0.0](https://github.com/DaveWoodCom/XCGLogger/tree/swift_3.0) for Swift 3.0
* XCGLogger version [3.6.0](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_3.6.0) for Swift 2.3
* XCGLogger version [3.5.3](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_3.5.3) for Swift 2.2
* XCGLogger version [3.2](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_3.2) for Swift 2.0-2.1
* XCGLogger version [2.x](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_2.4) for Swift 1.2
* XCGLogger version [1.x](https://github.com/DaveWoodCom/XCGLogger/releases/tag/Version_1.8.1) for Swift 1.1 and below.

##Basic Usage (Quick Start)

Add the XCGLogger project as a subproject to your project, and add the appropriate library as a dependancy of your target(s).
Under the `General` tab of your target, add the `XCGLogger.framework` to the `Embedded Binaries`.

Then, in each source file:

```Swift
import XCGLogger
```

In your AppDelegate, declare a global constant to the default XCGLogger instance.

```Swift
let log = XCGLogger.defaultInstance()
```

In the
```Swift
application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) // iOS, tvOS
```

or

```Swift
applicationDidFinishLaunching(aNotification: NSNotification) // OS X
```

function, configure the options you need:

```Swift
log.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "path/to/file", fileLogLevel: .Debug)
```

The value for `writeToFile:` can be a `String` or `NSURL`. If the file already exists, it will be cleared before we use it. Omit a value or set it to `nil` to log to the console only. You can optionally set a different log level for the file output using the `fileLogLevel` parameter. Set it to `nil` or omit it to use the same log level as the console.

Then, whenever you'd like to log something, use one of the convenience methods:

```Swift
log.verbose("A verbose message, usually useful when working on a specific problem")
log.debug("A debug message")
log.info("An info message, probably useful to power users looking in console.app")
log.warning("A warning message, may indicate a possible error")
log.error("An error occurred, but it's recoverable, just info about what happened")
log.severe("A severe error occurred, we are likely about to crash now")
```

The different methods set the log level of the message. XCGLogger will only print messages with a log level that is >= its current log level setting.

##Advanced Usage (Recommended)

XCGLogger aims to be simple to use and get you up and running quickly with as few as 2 lines of code above. But it allows for much greater control and flexibility. Here's an example of configuring the logger to output to the Apple System Log as well as a file.

```Swift
// Create a logger object with no destinations
let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

// Create a destination for the system console log (via NSLog)
let systemLogDestination = XCGNSLogDestination(owner: log, identifier: "advancedLogger.systemLogDestination")

// Optionally set some configuration options
systemLogDestination.outputLogLevel = .Debug
systemLogDestination.showLogIdentifier = false
systemLogDestination.showFunctionName = true
systemLogDestination.showThreadName = true
systemLogDestination.showLogLevel = true
systemLogDestination.showFileName = true
systemLogDestination.showLineNumber = true
systemLogDestination.showDate = true

// Add the destination to the logger
log.addLogDestination(systemLogDestination)

// Create a file log destination
let fileLogDestination = XCGFileLogDestination(owner: log, writeToFile: "/path/to/file", identifier: "advancedLogger.fileLogDestination")

// Optionally set some configuration options
fileLogDestination.outputLogLevel = .Debug
fileLogDestination.showLogIdentifier = false
fileLogDestination.showFunctionName = true
fileLogDestination.showThreadName = true
fileLogDestination.showLogLevel = true
fileLogDestination.showFileName = true
fileLogDestination.showLineNumber = true
fileLogDestination.showDate = true

// Process this destination in the background
fileLogDestination.logQueue = XCGLogger.logQueue

// Add the destination to the logger
log.addLogDestination(fileLogDestination)

// Add basic app info, version info etc, to the start of the logs
log.logAppDetails()
```

You can configure each log destination with different options depending on your needs.

Another common usage pattern is to have multiple loggers, perhaps one for UI issues, one for networking, and another for data issues.

Each log destination can have its own log level. As a convenience, you can set the log level on the log object itself and it will pass that level to each destination. Then set the destinations that need to be different.

#####Log Anything

You can log strings:

```
log.debug("Hi there!")
```

or pretty much anything you want:

```
log.debug(true)
log.debug(CGPoint(x: 1.1, y: 2.2))
log.debug(MyEnum.Option)
log.debug((4, 2))
log.debug(["Device": "iPhone", "Version": 7])
```

#####Extending XCGLogger

You can create alternate log destinations (besides the two built in ones for the console and a file). Your custom log destination must implement the `XCGLogDestinationProtocol` protocol. Instantiate your object, configure it, and then add it to the `XCGLogger` object with `addLogDestination`. Take a look at `XCGConsoleLogDestination` and `XCGFileLogDestination` for examples.

#####Selectively Executing Code

All log methods operate on closures. Using the same syntactic sugar as Swift's `assert()` function, this approach ensures we don't waste resources building log messages that won't be printed anyway, while at the same time preserving a clean call site.

For example, the following log statement won't waste resources if the debug log level is suppressed:

```Swift
log.debug("The description of \(thisObject) is really expensive to create")
```

Similarly, let's say you have to iterate through a loop in order to do some calculation before logging the result. In Objective-C, you could put that code block between `#if` `#endif`, and prevent the code from running. But in Swift, previously you would need to still process that loop, wasting resources. With `XCGLogger` it's as simple as:

```Swift
log.debug {
    var total = 0.0
    for receipt in receipts {
        total += receipt.total
    }

    return "Total of all receipts: \(total)"
}
```

In cases where you wish to selectively execute code without generating a log line, return `nil`, or use one of the methods: `verboseExec`, `debugExec`, `infoExec`, `warningExec`, `errorExec`, and `severeExec`.

#####Custom Date Formats

You can create your own `NSDateFormatter` object and assign it to the logger.

```Swift
let dateFormatter = NSDateFormatter()
dateFormatter.dateFormat = "MM/dd/yyyy hh:mma"
dateFormatter.locale = NSLocale.currentLocale()
log.dateFormatter = dateFormatter
```

#####Enhancing Log Messages With Colour

XCGLogger supports the [XcodeColors plug-in](https://github.com/robbiehanson/XcodeColors). Once installed, each log level will have its own colour. These colours can be customized as desired. See the sample projects for examples. If using multiple logger's, you could alternatively set each logger to its own colour.

#####Initialization Using A Closure

Alternatively you can use a closure to initialize your global variable, so that all initialization is done in one place
```Swift
let log: XCGLogger = {
    let log = XCGLogger.defaultInstance()
    log.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLogLevel: .Debug)
    
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy hh:mma"
    dateFormatter.locale = NSLocale.currentLocale()
    log.dateFormatter = dateFormatter
    
    return log
}()
```

**Note**: This creates the log object lazily, which means it's not created until it's actually needed. This delays the initial output of the app information details. Because of this, I recommend forcing the log object to be created at app launch by just referencing `log` at the top of your `didFinishLaunching` method if you don't already log something on app launch.

#####Alternate Configurations

By using Swift build flags, different log levels can be used in debugging versus staging/production.
Go to Build settings -> Swift Compiler - Custom Flags -> Other Swift Flags and add `-DDEBUG` to the Debug entry.

```Swift
#if DEBUG
    log.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)
#else
    log.setup(.Severe, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)
#endif
```

You can set any number of options up in a similar fashion. See the updated iOSDemo app for an example of using different log destinations based on options, search for `USE_NSLOG`.

#####Background Log Processing

By default, the supplied log destinations will process the logs on the thread they're called on. This is to ensure the log message is displayed immediately when debugging an application. You can add a breakpoint immediately after a log call and see the results when the breakpoint hits.

However, if you're not actively debugging the application, processing the logs on the current thread can introduce a performance hit. You can now specify a destination process it's logs on a dispatch queue of your choice (or even use a default supplied one).

```Swift
fileLogDestination.logQueue = XCGLogger.logQueue
```	

or even

```Swift
fileLogDestination.logQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
```

This works extremely well when combined with the Alternate Configurations method above.

```Swift
#if DEBUG
    log.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)
#else
    log.setup(.Severe, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)
    if let consoleLog = log.logDestination(XCGLogger.Constants.baseConsoleLogDestinationIdentifier) as? XCGConsoleLogDestination {
        consoleLog.logQueue = XCGLogger.logQueue
    }
#endif
```

#####Append To Existing Log File

When using the advanced configuration of the logger (see Advanced Usage above), you can now specify that the logger append to an existing log file, instead of automatically overwriting it.

Add the optional `shouldAppend:` parameter when initializing the `XCGFileLogDestination` object. You can also add the `appendMarker:` parameter to add a marker to the log file indicating where a new instance of your app started appending. By default we'll add `-- ** ** ** --` if the parameter is omitted. Set it to `nil` to skip appending the marker.

```let fileLogDestination = XCGFileLogDestination(owner: log, writeToFile: "/path/to/file", identifier: "advancedLogger.fileLogDestination", shouldAppend: true, appendMarker: "-- Relauched App --")```


#####Log File Rotation

When logging to a file, you have the option to rotate the log file to an archived destination, and have the logger automatically create a new log file in place of the old one.

Using the `XCGFileLogDestination` object in your logger call the `rotateFile(archiveToFile:)` method. Pass either a path or file URL to a location you'd like to store the old file. The method will return `true` on success, after which you can do whatever you need with the old file, compress it, email it, etc.

**Hint**: see the `logDestination(identifier:)` method on XCGLogger, to get your current `XCGFileLogDestination` object, or save a reference to it when you create it using the advanced usage options above.


##Third Party Tools That Work With XCGLogger

[**XcodeColors:**](https://github.com/robbiehanson/XcodeColors) Enable colour in the Xcode console
<br />
[**KZLinkedConsole:**](https://github.com/krzysztofzablocki/KZLinkedConsole) Link from a log line directly to the code that produced it
<br />
[**XCGLoggerNSLoggerConnector:**](https://github.com/markuswinkler/XCGLoggerNSLoggerConnector) Send your logs to [NSLogger](https://github.com/fpillet/NSLogger)
<br />
[**firelog:**](http://jogabo.github.io/firelog/) Send your logs to [Firebase](https://www.firebase.com/)

##To Do

- Add more examples of some advanced use cases
- Add additional log destination types
- Add Objective-C support
- Add Swift Package Manager support
- Add Linux support

##More

If you find this library helpful, you'll definitely find these other tools helpful:

Watchdog: http://watchdogforxcode.com/  
Slender: http://martiancraft.com/products/slender  
Briefs: http://giveabrief.com/  

Also, please check out some of my other projects:

Rudoku: [App Store](https://itunes.apple.com/app/apple-store/id965105321?pt=17255&ct=github&mt=8&at=11lMGu)  
TV Tune Up: https://www.cerebralgardens.com/tvtuneup  

###Change Log

The change log is now in it's own file: [CHANGELOG.md](CHANGELOG.md)

