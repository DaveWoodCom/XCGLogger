//
//  LogFolderDestination.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Yvo van Beek on 2017-01-17.
//  Copyright © 2017 Yvo van Beek.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - LogFolder
/// A standard destination that outputs log details to files in a log folder
open class LogFolderDestination: FileDestination {
    // MARK: - Properties
    /// Logger that owns the destination object
    open override var owner: XCGLogger? {
        willSet { rotateFile() }
    }

    /// URL of the folder to log to
    open var writeToFolderURL: URL? = nil {
        didSet {
            writeToFolderURL = createLogFolder(url: writeToFolderURL)
            rotateFile()
        }
    }

    /// The details of the last log item that was processed
    open var lastLogDetails: LogDetails? = nil

    /// Option: the format of the log file name (will be passed to a date formatter)
    open var logFileFormat = "yyyyMMdd" {
        didSet { rotateFile() }
    }

    /// Option: the extension of the log file name (don't include a .)
    open var logFileExtension = "txt" {
        didSet { rotateFile() }
    }

    /// Option: the number of log files to keep
    open var logFilesToKeep = 10 {
        didSet { cleanUpLogs() }
    }

    // MARK: - Class Properties
    open class var defaultLogFolderURL: URL {
        let cacheFolderURL =  FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheFolderURL.appendingPathComponent("Logs")
    }

    // MARK: - Life Cycle
    public init(owner: XCGLogger? = nil, writeToFolder: Any?, identifier: String = "", appendMarker: String? = nil) {
        super.init(owner: nil, writeToFile: nil, identifier: identifier, shouldAppend: true, appendMarker: appendMarker)

        var folderURL: URL?
        if writeToFolder is NSString {
            folderURL = URL(fileURLWithPath: writeToFolder as! String)
        }
        else {
            folderURL = writeToFolder as? URL
        }

        defer {
            // Set the folder URL after init to trigger the didSet
            writeToFolderURL = folderURL
            super.owner = owner
        }
    }

    public convenience init(identifier: String = "", appendMarker: String? = nil) {
        let folderURL = type(of: self).defaultLogFolderURL
        self.init(writeToFolder: folderURL, identifier: identifier, appendMarker: appendMarker)
    }

    // MARK: - Folder / File Handling Methods
    /// Create a new log folder.
    ///
    /// - Parameters:   Nothing.
    ///
    /// - Returns:  The url for the new log file.
    ///
    open func createLogFolder(url: URL?) -> URL? {
        if let folderURL = url {
            try! FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        return url
    }

    /// Create a new log file url.
    ///
    /// - Parameters:   Nothing.
    ///
    /// - Returns:  The url for the new log file.
    ///
    open func createLogFile() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = logFileFormat

        let fileName = dateFormatter.string(from: Date())
        return writeToFolderURL?.appendingPathComponent(fileName).appendingPathExtension(logFileExtension)
    }

    /// Scan the log folder and delete log files that are no longer relevant.
    ///
    /// - Parameters:   Nothing.
    ///
    /// - Returns:      Nothing.
    ///
    open func cleanUpLogs() {
        // Get the log files and sort them by name descending
        var fileURLs = logFileURLs()
        fileURLs.sort(by: { $0.lastPathComponent > $1.lastPathComponent })

        // Do we have more than we want to keep? Remove the rest
        if fileURLs.count > logFilesToKeep {
            fileURLs.removeFirst(logFilesToKeep)
            fileURLs.forEach { try? FileManager.default.removeItem(at: $0) }
        }
    }

    /// Get the urls of the log files in the log folder.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///
    /// - Returns:
    ///     - true:     The log file should be rotated.
    ///     - false:    The log file doesn't have to be rotated.
    ///
    open func logFileURLs() -> [URL] {
        guard let folderURL = writeToFolderURL else { return [] }
        guard let fileUrls = try? FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: []) else { return [] }
        return fileUrls.filter { $0.pathExtension == logFileExtension }
    }

    /// Rotate the current log file.
    ///
    /// - Parameters:   Nothing.
    ///
    /// - Returns:      Nothing.
    ///
    open func rotateFile() {
        if let logFileURL = createLogFile(), logFileURL != writeToFileURL {
            writeToFileURL = logFileURL
        }
    }

    /// Determine if the log file should be rotated.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///
    /// - Returns:
    ///     - true:     The log file should be rotated.
    ///     - false:    The log file doesn't have to be rotated.
    ///
    open func shouldRotate(logDetails: LogDetails) -> Bool {
        guard let lastDetails = lastLogDetails else { return false }
        return !NSCalendar.current.isDate(lastDetails.date, inSameDayAs: logDetails.date)
    }

    // MARK: - Overridden Methods
    /// Apply filters and formatters to the message before queuing it to be written by the write method.
    ///
    /// - Parameters:
    ///     - logDetails:   The log details.
    ///     - message:   Message ready to be formatted for output.
    ///
    /// - Returns:  Nothing
    ///
    override open func output(logDetails: LogDetails, message: String) {
        let rotate = shouldRotate(logDetails: logDetails)
        lastLogDetails = logDetails

        if rotate {
            rotateFile()
        }

        super.output(logDetails: logDetails, message: message)
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
    @discardableResult override open func rotateFile(to archiveToFile: Any) -> Bool {
        DispatchQueue.global().async { [weak self] in
            self?.cleanUpLogs()
        }
        
        return super.rotateFile(to: archiveToFile)
    }
}
