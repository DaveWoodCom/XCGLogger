#XCGLogger
#####By: Dave Wood
- Cerebral Gardens http://www.cerebralgardens.com/
- Twitter: [@CerebralGardens](https://twitter.com/CerebralGardens)

###tl;dr
A debug log module for use in Swift projects. Allows you to log details to the console (and optionally a file), just like you would have with NSLog or println, but with additional information such as the date, function name, filename and line number.

Go from this:

```Simple message```

to this:

```2014-06-09 06:44:43.600 [Debug] [AppDelegate.swift:40] application(_:didFinishLaunchingWithOptions:): Simple message```

###Compatibility

XCGLogger works in both iOS and OS X projects. It is a Swift library intended for use in Swift projects.

Swift does away with the C preprocessor, which kills the ability to use ```#define``` macros. This means our traditional way of generating nice debug logs is dead. Resorting to just plain old ```println``` calls means you lose a lot of helpful information, or requires you to type a lot more code.

**Note:** There are a few differences in Swift between 1.0 (Xcode 6) and 1.1 (Xcode 6.1), the code in this repo should work on (and will be updated for) the latest version of Swift by default. If you're using Xcode 6.0.1, I've added a file ```XCGLogger_Xcode601.swift``` to the project that makes XCGLogger backwards compatible. You just need to include the file in the three targets: XCGLogger (iOS), XCGLogger (OS X), and XCGLoggerTests in the XCGLogger project.

###How to Use

Add the XCGLogger project as a subproject to your project, and add either the iOS or OS X library as a dependancy of your target(s).

Then, in each source file:

```Swift
import XCGLogger
```

In your AppDelegate, declare a global constant to the default XCGLogger instance.

```Swift
let log = XCGLogger.defaultInstance()
```

**Note**: previously this was ```XCGLogger.sharedInstance()```, but it was changed to better reflect that you can create multiple instances.

In the 
```Swift
application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) // iOS
```

or

```Swift
applicationDidFinishLaunching(aNotification: NSNotification?) // OS X
```

function, configure the options you need:

```Swift
log.setup(logLevel: .Debug, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "path/to/file")
```

The value for ```writeToFile:``` can be a ```String``` or ```NSURL```. If the file already exists, it will be cleared before we use it. Omit a value or set it to nil to log to the console only.

Then, whenever you'd like to log something, use one of the convenience methods:

```Swift
log.verbose("A verbose message, usually useful when working on a specific problem")
log.debug("A debug message")
log.info("An info message, probably useful to power users looking in console.app")
log.error("An error occurred, but it's recoverable, just info about what happened")
log.severe("A severe error occurred, we are likely about to crash now")
```

The different methods set the log level of the message. XCGLogger will only print messages with a log level that is >= its current log level setting.

###Advanced Use

It's possible to create multiple instances of XCGLogger with different options. For example, you only want to log a specific section of your app to a file, perhaps to diagnose a specific issue a user is seeing. In that case, create alternate instances like this:

```Swift
let fileLog = XCGLogger()
fileLog.setup(logLevel: .Debug, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "path/to/file")
fileLog.info("Have a second instance for special use")
```

You can create alternate log destinations (besides the two built in ones for the console  and a file). Your custom log destination must implement the ```XCGLogDestinationProtocol``` protocol. Instantiate your object, configure it, and then add it to the ```XCGLogger``` object with ```addLogDestination```. Take a look at ```XCGConsoleLogDestination``` and ```XCGFileLogDestination``` for examples.

Each log destination can have its own log level. Setting the log level on the log object itself will pass that level to each destination. Then set the destinations that need to be different.

###Selectively Executing Code
As of version 1.2, you can now also selectively execute code based on the log level. This is useful for cases where you have to do some work in order to generate a log message, but don't want to do that work when the log messages won't be printed anyway.

For example, if you have to iterate through a loop in order to do some calculation before logging the result. In Objective-C, you could put that code block between ```#if``` ```#endif```, and prevent the code from running. But in Swift, previously you would need to still process that loop, wasting resources.

```Swift
log.debugExec {
    var total = 0.0
    for receipt in receipts {
	    total += receipt.total
    }
    
    log.debug("Total of all receipts: \(total)")
}

```

There are convenience methods for each log level:
```verboseExec```, ```debugExec```, ```infoExec```, ```errorExec```, ```severeExec```

###To Do
- Add examples of some advanced use cases
- Add additional log destination types

###More

If you find this library helpful, you'll definitely find these other tools helpful:

Watchdog: http://watchdogforxcode.com/

Slender: http://dragonforged.com/slender/

Briefs: http://giveabrief.com/


###Change Log

* **Version 1.7**: *(2014/09/27)* - Reorganized to be used as a subproject instead of a framework, fixed threading
* **Version 1.6**: *(2014/09/09)* - Updated for Xcode 6.1 Beta 1
* **Version 1.5**: *(2014/08/23)* - Updated for Xcode 6 Beta 6
* **Version 1.4**: *(2014/08/04)* - Updated for Xcode 6 Beta 5, removed __FUNCTION__ workaround
* **Version 1.3**: *(2014/07/27)* - Updated to use public/internal/private access modifiers
* **Version 1.2**: *(2014/07/01)* - Added exec methods to selectively execute code
* **Version 1.1**: *(2014/06/22)* - Changed the internal architecture to allow for more flexibility
* **Version 1.0**: *(2014/06/09)* - Initial Release


