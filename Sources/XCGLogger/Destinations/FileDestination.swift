//
//  FileDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

import Dispatch
import Foundation

// MARK: - FileDestination
/// A standard destination that outputs log details to a file
open class FileDestination: BaseDestination {

    public enum Rotation {
      case none
      case onlyAtAppStart
      case alsoWhileWriting

      public var description: String {
        switch self {
        case .none:
          return "None"
        case .onlyAtAppStart:
          return "onlyAtAppStart"
        case .alsoWhileWriting:
          return "alsoWhileWriting"
        }
      }
    }

    // MARK: - User accessible properties

    open var rotation = Rotation.none
    open var rotationFileSizeBytes = 1024 * 1024  // 1M
    open var rotationFilesMax = 1
    open var rotationFileDateFormat = "-yyyy-MM-dd'T'HH:mm"
    open var rotationFileHasSuffix = true

    /// Logger that owns the destination object
    open override var owner: XCGLogger? {
        didSet {
            if owner != nil {
                let path = writeToFileURL!.path
                let indexAfterSlash = path.range(of: "/", options: .backwards)!.upperBound
                logFileDirectory = path.substring(to: indexAfterSlash)

                if self.rotation != .none {
                    self.rotateFileAuto(cause: .onlyAtAppStart)
                }
                openFile()
            }
            else {
                closeFile()
            }
        }
    }

    /// The dispatch queue to process the log on
    open var logQueue: DispatchQueue? = nil

    /// FileURL of the file to log to
    open var writeToFileURL: URL? = nil {
        didSet {  // Note: will not be called (See https://bugs.swift.org/browse/SR-1118)
            openFile()
        }
    }

    /// File handle for the log file
    internal var logFileHandle: FileHandle? = nil

    /// Log file directory
    internal var logFileDirectory: String? = nil  // including trailing "/"

    /// Option: whether or not to append to the log file if it already exists
    internal var shouldAppend: Bool

    /// Option: if appending to the log file, the string to output at the start to mark where the append took place
    internal var appendMarker: String?

    // MARK: - Life Cycle
    public init(owner: XCGLogger? = nil, writeToFile: Any, identifier: String = "", shouldAppend: Bool = false, appendMarker: String? = "-- ** ** ** --") {
        self.shouldAppend = shouldAppend
        self.appendMarker = appendMarker

        if writeToFile is NSString {
            writeToFileURL = URL(fileURLWithPath: writeToFile as! String)
        }
        else if writeToFile is URL {
            writeToFileURL = writeToFile as? URL
        }
        else {
            writeToFileURL = nil
        }

        super.init(owner: owner, identifier: identifier)

        if owner != nil {
            openFile()
        }
    }

    deinit {
        // close file stream if open
        closeFile()
    }

    // MARK: - File Handling Methods
    /// Open the log file for writing.
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    private func openFile() {
        guard let owner = owner else { return }

        if logFileHandle != nil {
            closeFile()
        }

        if let writeToFileURL = writeToFileURL {

            let fileManager: FileManager = FileManager.default
            let fileExists: Bool = fileManager.fileExists(atPath: writeToFileURL.path)
            if !shouldAppend || !fileExists {
                fileManager.createFile(atPath: writeToFileURL.path, contents: nil, attributes: nil)
            }

            do {
                logFileHandle = try FileHandle(forWritingTo: writeToFileURL)
                if fileExists && shouldAppend {
                    logFileHandle?.seekToEndOfFile()

                    if let appendMarker = appendMarker,
                        let encodedData = "\(appendMarker)\n".data(using: String.Encoding.utf8) {

                        _try({
                            self.logFileHandle?.write(encodedData)
                        },
                        catch: { (exception: NSException) in
                            owner._logln("Objective-C Exception occurred: \(exception)", level: .error)
                        })
                    }
                }
            }
            catch let error as NSError {
                owner._logln("Attempt to open log file for \(fileExists && shouldAppend ? "appending" : "writing") failed: \(error.localizedDescription)", level: .error)
                logFileHandle = nil
                return
            }

            owner.logAppDetails(selectedDestination: self)

            let logDetails = LogDetails(level: .info, date: Date(), message: "XCGLogger " + (fileExists && shouldAppend ? "appending" : "writing") + " log to: " + writeToFileURL.absoluteString, functionName: "", fileName: "", lineNumber: 0, userInfo: XCGLogger.Constants.internalUserInfo)
            owner._logln(logDetails.message, level: logDetails.level)
            if owner.destination(withIdentifier: identifier) == nil {
                processInternal(logDetails: logDetails)
            }
        }
    }

    /// Close the log file.
    ///
    /// - Parameters:   None
    ///
    /// - Returns:  Nothing
    ///
    private func closeFile() {
        logFileHandle?.closeFile()
        logFileHandle = nil
    }

    /// Rotate the log file, storing the existing log file in the specified location.
    ///
    /// - Parameters:
    ///     - archiveToFile:    FileURL or path (as String) to where the existing log file should be rotated to.
    ///
    /// - Returns:
    ///     - true:     Log file rotated successfully.
    ///     - false:    Error rotating the log file.
    ///
    @discardableResult open func rotateFile(to archiveToFile: Any) -> Bool {
        var archiveToFileURL: URL? = nil

        if archiveToFile is NSString {
            archiveToFileURL = URL(fileURLWithPath: archiveToFile as! String)
        }
        else if archiveToFile is URL {
            archiveToFileURL = archiveToFile as? URL
        }
        else {
            return false
        }

        if let archiveToFileURL = archiveToFileURL,
            let writeToFileURL = writeToFileURL {

            let fileManager: FileManager = FileManager.default
            guard !fileManager.fileExists(atPath: archiveToFileURL.path) else { return false }

            closeFile()
            haveLoggedAppDetails = false

            do {
                try fileManager.moveItem(atPath: writeToFileURL.path, toPath: archiveToFileURL.path)
            }
            catch let error as NSError {
                rotationFailedBefore = true
                openFile()
                owner?._logln("Unable to rotate file \(writeToFileURL.path) to \(archiveToFileURL.path): \(error.localizedDescription)", level: .error)
                return false
            }

            owner?._logln("Rotated file \(writeToFileURL.path) to \(archiveToFileURL.path)", level: .info)
            openFile()
            return true
        }

        return false
    }

    // MARK: - Overridden Methods
    /// Write the log to the log file.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:         Formatted/processed message ready for output.
    ///
    /// - Returns:  Nothing
    ///
    open override func output(logDetails: LogDetails, message: String) {

        let outputClosure = {
            var logDetails = logDetails
            var message = message

            // Apply filters, if any indicate we should drop the message, we abort before doing the actual logging
            if self.shouldExclude(logDetails: &logDetails, message: &message) {
                return
            }

            self.applyFormatters(logDetails: &logDetails, message: &message)

            if let encodedData = "\(message)\n".data(using: String.Encoding.utf8) {
                _try({
                    self.logFileHandle?.write(encodedData)
                },
                catch: { (exception: NSException) in
                    self.owner?._logln("Objective-C Exception occurred: \(exception)", level: .error)
                })
            }

            guard self.rotation == .alsoWhileWriting else {return}
            self.rotateFileAuto(cause: .alsoWhileWriting)
        }
        
        if let logQueue = logQueue {
            logQueue.async(execute: outputClosure)
        }
        else {
            outputClosure()
        }
    }

    /// private properties for log rotation
    private var rotationFailedBefore = false
    private var rotateAutoCalledBefore = false
    private var logFileBaseName = ""
    private var logFileSuffix = ""  // including leading "." if there is suffix

    /// Rotate log file if it has exceeded the file size limit
    ///
    /// - Parameters:  What causes the rotation attempt
    ///
    /// - Returns:  Nothing
    ///
    func rotateFileAuto(cause: Rotation) {  // parameter unnecessary. for clarity only
      let fileManager = FileManager.default
      let path = writeToFileURL!.path

      // prepare parts of rotation file name for future use
      if (!rotateAutoCalledBefore) {
        let indexAfterSlash = path.range(of: "/", options: .backwards)!.upperBound
        let fileName = path.substring(from: indexAfterSlash)

        logFileBaseName = fileName
        logFileSuffix = ""

        // if there is a "." in file name and the file does use suffix
        if let dotRange = fileName.range(of: ".", options: .backwards),
          rotationFileHasSuffix {
          logFileBaseName = fileName.substring(to: dotRange.lowerBound)
          logFileSuffix = fileName.substring(from: dotRange.lowerBound)
        }
        rotateAutoCalledBefore = true
      }

      guard !rotationFailedBefore else {return}  // having seen failure before
      guard fileManager.fileExists(atPath: path) else {return}
      var action = ""  // for the catch clause to report error

      do {
        // quit if log file is not large enough yet
        action = "get attributes of " + path
        let fileAttr = try fileManager.attributesOfItem(atPath: path)
        let fileSize = fileAttr[FileAttributeKey.size] as! NSNumber
        guard fileSize.intValue > rotationFileSizeBytes else {return}

        // form rotation file name
        let formatter = DateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale!
        formatter.dateFormat = rotationFileDateFormat
        let dateString = formatter.string(from: Date())
        let rotationFilePath = logFileDirectory! + logFileBaseName + dateString + logFileSuffix

        // actually rotate
        owner?._logln("Auto rotate for \(cause.description) at size \(fileSize.intValue)", level: .info)

        let ret = rotateFile(to: rotationFilePath)
        guard ret else {return}  // no new file => no need to delete old ones

        // rotation successful.  delete older files
        let allLogFiles = logFilesNewestFirst()
        guard allLogFiles.count > rotationFilesMax + 1 else {return}

        for f in allLogFiles.suffix(from: rotationFilesMax + 1) {  // add 1 for main log file
          action = "delete " + f
          try fileManager.removeItem(atPath: f)
          owner?._logln("Delete old log file \(f)", level: .info)
        }
      } catch let error as NSError {
        owner?._logln("Failed to \(action): \(error.localizedDescription)", level: .error)
        return
      }
    }

    /// Return all log files, sorted, newest first
    ///
    /// - Parameters:  None
    ///
    /// - Returns:  Array of log files, sorted
    ///
    private func logFilesNewestFirst() -> [String] {
      var sortedFiles = [String]()
      var action = ""

      do {
        let fileManager = FileManager.default

        // assemble a dictionary of date:file
        var fileDateMap = [NSDate: String]()
        let iter = fileManager.enumerator(atPath: logFileDirectory!)
        while let element = iter?.nextObject() as? String {
          let filePath = logFileDirectory! + element
          action = "get attributes of " + filePath
          let fileAttr = try fileManager.attributesOfItem(atPath: filePath)
          let creationDate = fileAttr[FileAttributeKey.creationDate] as! NSDate
          fileDateMap[creationDate] = filePath
        }

        // sort the dates in the dictionary, newest first
        let compareDates: (NSDate, NSDate) -> Bool = {
          return $0.compare($1 as Date) == ComparisonResult.orderedDescending
        }
        let sortedDates = Array(fileDateMap.keys).sorted(by: compareDates)

        // assemble array of files using sorted dates
        for key in sortedDates {
           sortedFiles.append(fileDateMap[key]!)
        }

        return sortedFiles

      } catch let error as NSError {
        owner?._logln("Failed to \(action): \(error.localizedDescription)", level: .error)
        return []
      }
    }

    /// Return given number of most recent log files, newest first
    ///
    /// - Parameters: number of files to be returned
    ///
    /// - Returns: Array of log file URLs, sorted
    ///
    func mostRecentLogFiles(numFiles: Int) -> [URL] {
      var URLs = [URL]()
      var counter = 0
      for f in logFilesNewestFirst() {
        URLs.append(URL(fileURLWithPath: f))
        counter += 1
        guard counter < numFiles else {break}
      }
      return URLs
    }
}
