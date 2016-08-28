#Change Log

* **Version 3.5**: *(2016/08/23)* - Added the ability to log anything, no longer limited to strings, or required to use string interpolation. Thanks to @Zyphrax #130 and @mishimay #140. Can also now call a logging method with no parameters, such as `log.debug()`. This will log the result of customizable `testNoMessageClosure` property. By default that's just an empty string, but should allow for some interesting features, (like an automatic counter). This will likely be the last version for Swift 2.x.
* **Version 3.4**: *(2016/08/21)* - Finally added an option to append to an existing log file, and added a basic log rotation method. Other bug fixes.
* **Version 3.3**: *(2016/03/27)* - Updated for Xcode 7.3 (Swift 2.2). If you're still using 7.2 (Swift 2.1), you must use XCGLogger 3.2.
* **Version 3.2**: *(2016/01/04)* - Added option to omit the default destination (for advanced usage), added background logging option
* **Version 3.1.1**: *(2015/11/18)* - Minor clean up, fixes an app submission issue for tvOS
* **Version 3.1**: *(2015/10/23)* - Initial support for tvOS
* **Version 3.1b1**: *(2015/09/09)* - Initial support for tvOS
* **Version 3.0**: *(2015/09/09)* - Bug fix, and WatchOS 2 suppport (thanks @ymyzk)
* **Version 2.4**: *(2015/09/09)* - Minor bug fix, likely the last release for Swift 1.x
* **Version 3.0b3**: *(2015/08/24)* - Added option to include the log identifier in log messages #79
* **Version 2.3**: *(2015/08/24)* - Added option to include the log identifier in log messages #79
* **Version 3.0b2**: *(2015/08/11)* - Updated for Swift 2.0 (Xcode 7 Beta 5)
* **Version 2.2**: *(2015/08/11)* - Internal restructuring, easier to create new log destination subclasses. Can disable function names, and/or dates. Added optional new log destination that uses NSLog instead of println().
* **Version 3.0b1**: *(2015/06/18)* - Swift 2.0 support/required. Consider this unstable for now, as Swift 2.0 will likely see changes before final release, and this library may undergo some architecture changes (time permitting).
* **Version 2.1.1**: *(2015/06/18)* - Fixed two minor bugs wrt XcodeColors.
* **Version 2.1**: *(2015/06/17)* - Added support for XcodeColors (https://github.com/robbiehanson/XcodeColors). Undeprecated the \*Exec() methods.
* **Version 2.0**: *(2015/04/14)* - Requires Swift 1.2. Removed some workarounds/hacks for older versions of Xcode. Removed thread based caching of NSDateFormatter objects since they're now thread safe. You can now use the default date formatter, or create and assign your own and it'll be used. Added Thread name option (Thanks to Nick Strecker https://github.com/tekknick ). Add experimental support for CocoaPods. 
* **Version 1.9**: *(2015/04/14)* - Deprecated the \*Exec() methods in favour of just using a trailing closure on the logging methods (Thanks to Nick Strecker https://github.com/tekknick ). This will be the last version for Swift 1.1.
* **Version 1.8.1**: *(2014/12/31)* - Added a workaround to the Swift compiler's optimization bug, restored optimization level back to Fastest
* **Version 1.8**: *(2014/11/16)* - Added warning log level (Issue #16)
* **Version 1.7**: *(2014/09/27)* - Reorganized to be used as a subproject instead of a framework, fixed threading
* **Version 1.6**: *(2014/09/09)* - Updated for Xcode 6.1 Beta 1
* **Version 1.5**: *(2014/08/23)* - Updated for Xcode 6 Beta 6
* **Version 1.4**: *(2014/08/04)* - Updated for Xcode 6 Beta 5, removed `__FUNCTION__` workaround
* **Version 1.3**: *(2014/07/27)* - Updated to use public/internal/private access modifiers
* **Version 1.2**: *(2014/07/01)* - Added exec methods to selectively execute code
* **Version 1.1**: *(2014/06/22)* - Changed the internal architecture to allow for more flexibility
* **Version 1.0**: *(2014/06/09)* - Initial Release

