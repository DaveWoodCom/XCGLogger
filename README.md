![XCGLogger][xcglogger-logo]

[![badge-language]][swift.org]
[![badge-platforms]][swift.org]
[![badge-license]][license]

[![badge-travis]][travis]
[![badge-swiftpm]][swiftpm]
[![badge-cocoapods]][cocoapods-xcglogger]
[![badge-carthage]][carthage]

[![badge-sponsors]][cerebral-gardens]
[![badge-twitter]][twitter-davewoodx]

## tl;dr
XCGLogger is the original debug log module for use in Swift projects. 

Swift does not include a C preprocessor so developers are unable to use the debug log `#define` macros they would use in Objective-C. This means our traditional way of generating nice debug logs no longer works. Resorting to just plain old `print` calls means you lose a lot of helpful information, or requires you to type a lot more code.

XCGLogger allows you to log details to the console (and optionally a file, or other custom destinations), just like you would have with `NSLog()` or `print()`, but with additional information, such as the date, function name, filename and line number.

Go from this:

```Simple message```

to this:

```2014-06-09 06:44:43.600 [Debug] [AppDelegate.swift:40] application(_:didFinishLaunchingWithOptions:): Simple message```

#### Example
<img src="https://raw.githubusercontent.com/DaveWoodCom/XCGLogger/master/ReadMeImages/SampleLog.png" alt="Example" style="width: 690px;" />

### Communication _(Hat Tip AlamoFire)_

* If you need help, use [Stack Overflow][stackoverflow] (Tag '[xcglogger][stackoverflow]').
* If you'd like to ask a general question, use [Stack Overflow][stackoverflow].
* If you've found a bug, open an issue.
* If you have a feature request, open an issue.
* If you want to contribute, submit a pull request.
* If you use XCGLogger, please Star the project on [GitHub][github-xcglogger]

## Installation

### Git Submodule

Execute:

```git submodule add https://github.com/DaveWoodCom/XCGLogger.git```
	
in your repository folder.

### [Carthage][carthage]

Add the following line to your `Cartfile`.

```github "DaveWoodCom/XCGLogger" ~> 5.0.1```

Then run `carthage update --no-use-binaries` or just `carthage update`. For details of the installation and usage of Carthage, visit [it's project page][carthage].

### [CocoaPods][cocoapods]

Add something similar to the following lines to your `Podfile`. You may need to adjust based on your platform, version/branch etc.

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'XCGLogger', '~> 5.0.1'
```

Specifying the pod `XCGLogger` on its own will include the core framework. We're starting to add subspecs to allow you to include optional components as well:

`pod 'XCGLogger/UserInfoHelpers', '~> 5.0.1'`: Include some experimental code to help deal with using UserInfo dictionaries to tag log messages.

Then run `pod install`. For details of the installation and usage of CocoaPods, visit [it's official web site][cocoapods].

### [Swift Package Manager][swiftpm]

Add the following entry to your package's dependencies:

```
.Package(url: "https://github.com/DaveWoodCom/XCGLogger.git", majorVersion: 5)
```	

### Backwards Compatibility

Use:
* XCGLogger version [5.0.1][xcglogger-5.0.1] for Swift 3.0-3.1
* XCGLogger version [3.6.0][xcglogger-3.6.0] for Swift 2.3
* XCGLogger version [3.5.3][xcglogger-3.5.3] for Swift 2.2
* XCGLogger version [3.2][xcglogger-3.2] for Swift 2.0-2.1
* XCGLogger version [2.x][xcglogger-2.x] for Swift 1.2
* XCGLogger version [1.x][xcglogger-1.x] for Swift 1.1 and below.

## Basic Usage (Quick Start)

_This quick start method is intended just to get you up and running with the logger. You should however use the [advanced usage below](#advanced-usage-recommended) to get the most out of this library._

Add the XCGLogger project as a subproject to your project, and add the appropriate library as a dependancy of your target(s).
Under the `General` tab of your target, add `XCGLogger.framework` and `ObjcExceptionBridging.framework` to the `Embedded Binaries` section.

Then, in each source file:

```Swift
import XCGLogger
```

In your AppDelegate (or other global file), declare a global constant to the default XCGLogger instance.

```Swift
let log = XCGLogger.default
```

In the
```Swift
application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) // iOS, tvOS
```

or

```Swift
applicationDidFinishLaunching(_ notification: Notification) // macOS
```

function, configure the options you need:

```Swift
log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: "path/to/file", fileLevel: .debug)
```

The value for `writeToFile:` can be a `String` or `URL`. If the file already exists, it will be cleared before we use it. Omit the parameter or set it to `nil` to log to the console only. You can optionally set a different log level for the file output using the `fileLevel:` parameter. Set it to `nil` or omit it to use the same log level as the console.

Then, whenever you'd like to log something, use one of the convenience methods:

```Swift
log.verbose("A verbose message, usually useful when working on a specific problem")
log.debug("A debug message")
log.info("An info message, probably useful to power users looking in console.app")
log.warning("A warning message, may indicate a possible error")
log.error("An error occurred, but it's recoverable, just info about what happened")
log.severe("A severe error occurred, we are likely about to crash now")
```

The different methods set the log level of the message. XCGLogger will only print messages with a log level that is greater to or equal to it's current log level setting. So a logger with a level of `.error` will only output log messages with a level of `.error`, or `.severe`.

## Advanced Usage (Recommended)

XCGLogger aims to be simple to use and get you up and running quickly with as few as 2 lines of code above. But it allows for much greater control and flexibility. 

A logger can be configured to deliver log messages to a variety of destinations. Using the basic setup above, the logger will output log messages to the standard Xcode debug console, and optionally a file if a path is provided. It's quite likely you'll want to send logs to more interesting places, such as the Apple System Console, a database, third party server, or another application such as [NSLogger][NSLogger]. This is accomplished by adding the destination to the logger.

Here's an example of configuring the logger to output to the Apple System Log as well as a file.

```Swift
// Create a logger object with no destinations
let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

// Create a destination for the system console log (via NSLog)
let systemDestination = AppleSystemLogDestination(identifier: "advancedLogger.systemDestination")

// Optionally set some configuration options
systemDestination.outputLevel = .Debug
systemDestination.showLogIdentifier = false
systemDestination.showFunctionName = true
systemDestination.showThreadName = true
systemDestination.showLevel = true
systemDestination.showFileName = true
systemDestination.showLineNumber = true
systemDestination.showDate = true

// Add the destination to the logger
log.add(destination: systemDestination)

// Create a file log destination
let fileDestination = FileDestination(writeToFile: "/path/to/file", identifier: "advancedLogger.fileDestination")

// Optionally set some configuration options
fileDestination.outputLevel = .Debug
fileDestination.showLogIdentifier = false
fileDestination.showFunctionName = true
fileDestination.showThreadName = true
fileDestination.showLevel = true
fileDestination.showFileName = true
fileDestination.showLineNumber = true
fileDestination.showDate = true

// Process this destination in the background
fileDestination.logQueue = XCGLogger.logQueue

// Add the destination to the logger
log.add(destination: fileDestination)

// Add basic app info, version info etc, to the start of the logs
log.logAppDetails()
```

You can configure each log destination with different options depending on your needs.

Another common usage pattern is to have multiple loggers, perhaps one for UI issues, one for networking, and another for data issues.

Each log destination can have its own log level. As a convenience, you can set the log level on the log object itself and it will pass that level to each destination. Then set the destinations that need to be different.

**Note**: A destination object can only be added to one logger object, adding it to a second will remove it from the first.

### Initialization Using A Closure

Alternatively you can use a closure to initialize your global variable, so that all initialization is done in one place
```Swift
let log: XCGLogger = {
    let log = XCGLogger(identifier: "advancedLogger", includeDefaultDestinations: false)

	// Customize as needed
    
    return log
}()
```

**Note**: This creates the log object lazily, which means it's not created until it's actually needed. This delays the initial output of the app information details. Because of this, I recommend forcing the log object to be created at app launch by adding the line `let _ = log` at the top of your `didFinishLaunching` method if you don't already log something on app launch.

### Log Anything

You can log strings:

```Swift
log.debug("Hi there!")
```

or pretty much anything you want:

```Swift
log.debug(true)
log.debug(CGPoint(x: 1.1, y: 2.2))
log.debug(MyEnum.Option)
log.debug((4, 2))
log.debug(["Device": "iPhone", "Version": 7])
```

### Filtering Log Messages

New to XCGLogger 4, you can now create filters to apply to your logger (or to specific destinations). Create and configure your filters (examples below), and then add them to the logger or destination objects by setting the optional `filters` property to an array containing the filters. Filters are applied in the order they exist in the array. During processing, each filter is asked if the log message should be excluded from the log. If any filter excludes the log message, it's excluded. Filters have no way to reverse the exclusion of another filter.

If a destination's `filters` property is `nil`, the log's `filters` property is used instead. To have one destination log everything, while having all other destinations filter something, add the filters to the log object and set the one destination's `filters` property to an empty array `[]`. 

**Note**: Unlike destinations, you can add the same filter object to multiple loggers and/or multiple destinations.

#### Filter by Filename

To exclude all log messages from a specific file, create an exclusion filter like so:

```Swift
log.filters = [FileNameFilter(excludeFrom: ["AppDelegate.swift"], excludePathWhenMatching: true)]
```

`excludeFrom:` takes an `Array<String>` or `Set<String>` so you can specify multiple files at the same time.

`excludePathWhenMatching:` defaults to `true` so you can omit it unless you want to match path's as well.

To include log messages only for a specific set to files, create the filter using the `includeFrom:` initializer. It's also possible to just toggle the `inverse` property to flip the exclusion filter to an inclusion filter.
	
#### Filter by Tag

In order to filter log messages by tag, you must of course be able to set a tag on the log messages. Each log message can now have additional, user defined data attached to them, to be used by filters (and/or formatters etc). This is handled with a `userInfo: Dictionary<String, Any>` object. The dictionary key should be a namespaced string to avoid collisions with future additions. Official keys will begin with `com.cerebralgardens.xcglogger`. The tag key can be accessed by `XCGLogger.Constants.userInfoKeyTags`. You definitely don't want to be typing that, so feel free to create a global shortcut: `let tags = XCGLogger.Constants.userInfoKeyTags`. Now you can easily tag your logs:

```Swift
let sensitiveTag = "Sensitive"
log.debug("A tagged log message", userInfo: [tags: sensitiveTag])
```

The value for tags can be an `Array<String>`, `Set<String>`, or just a `String`, depending on your needs. They'll all work the same way when filtered.

Depending on your workflow and usage, you'll probably create faster methods to set up the `userInfo` dictionary. See [below](#mixing-and-matching) for other possible shortcuts.

Now that you have your logs tagged, you can filter easily:

```Swift
log.filters = [TagFilter(excludeFrom: [sensitiveTag])]
```

Just like the `FileNameFilter`, you can use `includeFrom:` or toggle `inverse` to include only log messages that have the specified tags.

#### Filter by Developer

Filtering by developer is exactly like filtering by tag, only using the `userInfo` key of `XCGLogger.Constants.userInfoKeyDevs`. In fact, both filters are subclasses of the `UserInfoFilter` class that you can use to create additional filters. See [Extending XCGLogger](#extending-xcglogger) below.

#### Mixing and Matching

In large projects with multiple developers, you'll probably want to start tagging log messages, as well as indicate the developer that added the message.

While extremely flexible, the `userInfo` dictionary can be a little cumbersome to use. There are a few possible methods you can use to simply things. I'm still testing these out myself so they're not officially part of the library yet (I'd love feedback or other suggestions).

I have created some experimental code to help create the UserInfo dictionaries. (Include the optional `UserInfoHelpers` subspec if using CocoaPods). Check the iOS Demo app to see it in use.

There are two structs that conform to the `UserInfoTaggingProtocol` protocol. `Tag` and `Dev`.

You can create an extension on each of these that suit your project. For example:

```Swift
extension Tag {
    static let sensitive = Tag("sensitive")
    static let ui = Tag("ui")
    static let data = Tag("data")
}

extension Dev {
    static let dave = Dev("dave")
    static let sabby = Dev("sabby")
}
```

Along with these types, there's an overloaded operator `|` that can be used to merge them together into a dictionary compatible with the `UserInfo:` parameter of the logging calls.

Then you can log messages like this:

```Swift
log.debug("A tagged log message", userInfo: Dev.dave | Tag.sensitive)
```

There are some current issues I see with these `UserInfoHelpers`, which is why I've made it optional/experimental for now. I'd love to hear comments/suggestions for improvements.

1. The overloaded operator `|` merges dictionaries so long as there are no `Set`s. If one of the dictionaries contains a `Set`, it'll use one of them, without merging them. Preferring the left hand side if both sides have a set for the same key.
2. Since the `userInfo:` parameter needs a dictionary, you can't pass in a single Dev or Tag object. You need to use at least two with the `|` operator to have it automatically convert to a compatible dictionary. If you only want one Tag for example, you must access the `.dictionary` parameter manually: `userInfo: Tag("Blah").dictionary`.

### Selectively Executing Code

All log methods operate on closures. Using the same syntactic sugar as Swift's `assert()` function, this approach ensures we don't waste resources building log messages that won't be output anyway, while at the same time preserving a clean call site.

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

### Custom Date Formats

You can create your own `DateFormatter` object and assign it to the logger.

```Swift
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "MM/dd/yyyy hh:mma"
dateFormatter.locale = Locale.current
log.dateFormatter = dateFormatter
```

### Enhancing Log Messages With Colour

XCGLogger supports adding formatting codes to your log messages to enable colour in various places. The original option was to use the [XcodeColors plug-in][XcodeColors]. However, Xcode 8 no longer officially supports plug-ins. You can still view your logs in colour, just not in Xcode 8 at the moment ([see note below](#restore-plug-in-support)). You can still use Xcode 7 if desired (after adding the Swift 3 toolchain), or you can use the new ANSI colour support to add colour to your fileDestination objects and view your logs via a terminal window. This gives you some extra options such as adding Bold, Italics, or (please don't) Blinking!

Once enabled, each log level can have its own colour. These colours can be customized as desired. If using multiple loggers, you could alternatively set each logger to its own colour.

An example of setting up the ANSI formatter:

```Swift
if let fileDestination: FileDestination = log.destination(withIdentifier: XCGLogger.Constants.fileDestinationIdentifier) as? FileDestination {
    let ansiColorLogFormatter: ANSIColorLogFormatter = ANSIColorLogFormatter()
    ansiColorLogFormatter.colorize(level: .verbose, with: .colorIndex(number: 244), options: [.faint])
    ansiColorLogFormatter.colorize(level: .debug, with: .black)
    ansiColorLogFormatter.colorize(level: .info, with: .blue, options: [.underline])
    ansiColorLogFormatter.colorize(level: .warning, with: .red, options: [.faint])
    ansiColorLogFormatter.colorize(level: .error, with: .red, options: [.bold])
    ansiColorLogFormatter.colorize(level: .severe, with: .white, on: .red)
    fileDestination.formatters = [ansiColorLogFormatter]
}
```

As with filters, you can use the same formatter objects for multiple loggers and/or multiple destinations. If a destination's `formatters` property is `nil`, the logger's `formatters` property will be used instead.

See [Extending XCGLogger](#extending-xcglogger) below for info on creating your own custom formatters.

### Alternate Configurations

By using Swift build flags, different log levels can be used in debugging versus staging/production.
Go to Build Settings -> Swift Compiler - Custom Flags -> Other Swift Flags and add `-DDEBUG` to the Debug entry.

```Swift
#if DEBUG
    log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
#else
    log.setup(level: .severe, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
#endif
```

You can set any number of options up in a similar fashion. See the updated iOSDemo app for an example of using different log destinations based on options, search for `USE_NSLOG`.

### Background Log Processing

By default, the supplied log destinations will process the logs on the thread they're called on. This is to ensure the log message is displayed immediately when debugging an application. You can add a breakpoint immediately after a log call and see the results when the breakpoint hits.

However, if you're not actively debugging the application, processing the logs on the current thread can introduce a performance hit. You can now specify a destination process it's logs on a dispatch queue of your choice (or even use a default supplied one).

```Swift
fileDestination.logQueue = XCGLogger.logQueue
```	

or even

```Swift
fileDestination.logQueue = DispatchQueue.global(qos: .background)
```

This works extremely well when combined with the [Alternate Configurations](#alternate-configurations) method above.

```Swift
#if DEBUG
    log.setup(level: .debug, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
#else
    log.setup(level: .severe, showThreadName: true, showLevel: true, showFileNames: true, showLineNumbers: true)
    if let consoleLog = log.logDestination(XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination {
        consoleLog.logQueue = XCGLogger.logQueue
    }
#endif
```

### Append To Existing Log File

When using the advanced configuration of the logger (see [Advanced Usage above](#advanced-usage-recommended)), you can now specify that the logger append to an existing log file, instead of automatically overwriting it.

Add the optional `shouldAppend:` parameter when initializing the `FileDestination` object. You can also add the `appendMarker:` parameter to add a marker to the log file indicating where a new instance of your app started appending. By default we'll add `-- ** ** ** --` if the parameter is omitted. Set it to `nil` to skip appending the marker.

```let fileDestination = FileDestination(writeToFile: "/path/to/file", identifier: "advancedLogger.fileDestination", shouldAppend: true, appendMarker: "-- Relauched App --")```


### Automatic Log File Rotation

When logging to a file, you have the option to automatically rotate the log file to an archived destination, and have the logger automatically create a new log file in place of the old one.

Create a destination using the `AutoRotatingFileDestination` class and set the following properties:

`targetMaxFileSize`: Auto rotate once the file is larger than this

`targetMaxTimeInterval`: Auto rotate after this many seconds

`targetMaxLogFiles`: Number of archived log files to keep, older ones are automatically deleted

Those are all guidelines for the logger, not hard limits.

### Extending XCGLogger

You can create alternate log destinations (besides the built in ones). Your custom log destination must implement the `DestinationProtocol` protocol. Instantiate your object, configure it, and then add it to the `XCGLogger` object with `add(destination:)`. There are two base destination classes (`BaseDestination` and `BaseQueuedDestination`) you can inherit from to handle most of the process for you, requiring you to only implement one additional method in your custom class. Take a look at `ConsoleDestination` and `FileDestination` for examples.

You can also create custom filters or formatters. Take a look at the provided versions as a starting point. Note that filters and formatters have the ability to alter the log messages as they're processed. This means you can create a filter that strips passwords, highlights specific words, encrypts messages, etc.

## Contributing

XCGLogger is the best logger available for Swift because of the contributions from the community like you. There are many ways you can help continue to make it great.

1. Star the project on [GitHub][github-xcglogger].
2. Report issues/bugs you find.
3. Suggest features.
4. Submit pull requests.

**Note**: when submitting a pull request, please use lots of small commits verses one huge commit. It makes it much easier to merge in when there are several pull requests that need to be combined for a new version.

## Third Party Tools That Work With XCGLogger

**Note**: These plug-ins no longer 'officially' work in Xcode 8. File a [bug report](http://openradar.appspot.com/27447585) if you'd like to see plug-ins return to Xcode. See [below](#xcode_8_tips) for a workaround...

[**XcodeColors:**][XcodeColors] Enable colour in the Xcode console
<br />
[**KZLinkedConsole:**][KZLinkedConsole] Link from a log line directly to the code that produced it

**Note**: These may not yet work with the Swift 3 version of XCGLogger.

[**XCGLoggerNSLoggerConnector:**][XCGLoggerNSLoggerConnector] Send your logs to [NSLogger][NSLogger]

## Xcode 8 Tips

### Restore Plug-In Support

One of the biggest issues you'll notice when using Xcode 8, is that by default it will no longer load plug-ins. Personally, I really like the benefits the plug-ins add to Xcode, especially XcodeColors. With so many other frameworks, or even Xcode itself spewing messages into the debug console, it's really helpful to be able to have your logs stand out with colour. It is currently possible to re-enable plug-ins in Xcode 8. If you do so, you'll be able to use the new `XcodeColorsLogFormatter` class to colour your log messages again. See the demo apps for example code.

**Be Warned**: If you follow these instructions to re-enable plug-ins, there could be unforeseen consequences. I would definitely only do this on a development machine, with the assumption that you have another machine (or at least an unmodified version of Xcode) to do your App Store/Distribution builds. **Do not** attempt to upload a binary to Apple that was built with a modified version of Xcode. **I take no responsibility for anything that happens if you follow these instructions. You have been warned**.

Now, assuming you've read the above warning, and you have a development only machine, and you really want to use your awesome plug-ins, here's my recommended method to re-enable plug-ins.

1. Clone the [unsign](https://github.com/steakknife/unsign) repository.
2. Build it following their dead-simple instructions (`make`).
3. Close Xcode if it's open.
4. In your favourite shell/terminal, execute the following commands (may need to be root, or just `sudo`):


	`cd /Applications/Xcode.app/Contents/MacOS` *Substitute another Xcode path if you like*
	
	`/path/to/unsign Xcode` *Creates a new `Xcode.unsigned` binary*
	
	`mv Xcode Xcode.signed` *Move the original file*
	
	`ln -sf Xcode.unsigned Xcode` *Link the unsigned version to the original filename*

5. Launch Xcode and use your favourite plug-ins. You may have to reauthorize access to your keychain, but it should be a one time task.
6. You can flip back and forth between the signed and unsigned versions by repeating the `ln -sf Xcode.unsigned Xcode` command, just changing `.unsigned` to `.signed` etc.
7. Do not use this version of Xcode to submit apps!
8. Pray Apple doesn't disable this workaround.
9. File a radar requesting official plug-in support again. You can dup this [radar](http://openradar.appspot.com/27447585).

Thanks to [@inket](https://github.com/inket/update_xcode_plugins) and [@steakknife](https://github.com/steakknife/unsign) for providing the knowledge and tools for this tip!

<!-- This tip no longer works as of macOS 10.12.4, it appears to disable all logs, on iOS now. 
-- ### Disable Xcode's Log Noise
-- 
-- For some reason, the simulators in the final version of Xcode 8 are printing lots of their own debug messages to the console. These messages make reading your own debug logs cumbersome. You can prevent those logs from being displayed by adding the environment variable `OS_ACTIVITY_MODE` to your debug scheme, and setting the value to `disable`.
-- 
-- <img src="https://raw.githubusercontent.com/DaveWoodCom/XCGLogger/swift_3.0/ReadMeImages/OSActivityMode.png" alt="Environment Variable" style="width: 690px; height: 401px;" />
-- 
-- Thanks to [@rustyshelf](https://twitter.com/rustyshelf/status/775505191160328194) and [@bersaelor](https://twitter.com/bersaelor/status/776317530549919744) for this tip!
-->

## To Do

- Add more examples of some advanced use cases
- Add additional log destination types
- Add Objective-C support
- Add Linux support

## More

If you find this library helpful, you'll definitely find these other tools helpful:

Watchdog: http://watchdogforxcode.com/  
Slender: http://martiancraft.com/products/slender  
Briefs: http://giveabrief.com/  

Also, please check out some of my other projects:

Rudoku: [App Store](https://itunes.apple.com/app/apple-store/id965105321?pt=17255&ct=github&mt=8&at=11lMGu)  
TV Tune Up: https://www.cerebralgardens.com/tvtuneup  

### Change Log

The change log is now in it's own file: [CHANGELOG.md](CHANGELOG.md)

[xcglogger-logo]: https://github.com/DaveWoodCom/XCGLogger/raw/master/ReadMeImages/XCGLoggerLogo_326x150.png
[swift.org]: https://swift.org/
[license]: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
[travis]: https://travis-ci.org/DaveWoodCom/XCGLogger
[swiftpm]: https://swift.org/package-manager/
[cocoapods]: https://cocoapods.org/
[cocoapods-xcglogger]: https://cocoapods.org/pods/XCGLogger
[carthage]: https://github.com/Carthage/Carthage
[cerebral-gardens]: https://www.cerebralgardens.com/
[twitter-davewoodx]: https://twitter.com/davewoodx
[github-xcglogger]: https://github.com/DaveWoodCom/XCGLogger
[stackoverflow]: http://stackoverflow.com/questions/tagged/xcglogger

[badge-language]: https://img.shields.io/badge/Swift-1.x%20%7C%202.x%20%7C%203.x-orange.svg?style=flat
[badge-platforms]: https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgray.svg?style=flat
[badge-license]: https://img.shields.io/badge/License-MIT-lightgrey.svg?style=flat
[badge-travis]: https://img.shields.io/travis/DaveWoodCom/XCGLogger/master.svg?style=flat
[badge-swiftpm]: https://img.shields.io/badge/Swift_Package_Manager-v5.0.1-64a6dd.svg?style=flat
[badge-cocoapods]: https://img.shields.io/cocoapods/v/XCGLogger.svg?style=flat
[badge-carthage]: https://img.shields.io/badge/Carthage-v5.0.1-64a6dd.svg?style=flat

[badge-sponsors]: https://img.shields.io/badge/Sponsors-Cerebral%20Gardens-orange.svg?style=flat
[badge-twitter]: https://img.shields.io/twitter/follow/DaveWoodX.svg?style=social

[XcodeColors]: https://github.com/robbiehanson/XcodeColors
[KZLinkedConsole]: https://github.com/krzysztofzablocki/KZLinkedConsole
[NSLogger]: https://github.com/fpillet/NSLogger
[XCGLoggerNSLoggerConnector]: https://github.com/markuswinkler/XCGLoggerNSLoggerConnector
[Firelog]: http://jogabo.github.io/firelog/
[Firebase]: https://www.firebase.com/

[xcglogger-5.0.1]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/5.0.1
[xcglogger-3.6.0]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/3.6.0
[xcglogger-3.5.3]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/3.5.3
[xcglogger-3.2]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/3.2.0
[xcglogger-2.x]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/2.4.0
[xcglogger-1.x]: https://github.com/DaveWoodCom/XCGLogger/releases/tag/1.8.1
