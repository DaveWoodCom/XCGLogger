//
//  UserInfoHelpers.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2016-09-19.
//  Copyright © 2016 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

/// Protocol for creating log userInfo

public protocol UserInfoConvertibleProtocol {
    
    /// Convert the object to a userInfo compatible dictionary
    var dictionary: [String: Any] { get }

}

/// Protocol for creating tagging objects (ie, a tag, a developer, etc) to filter log messages by

public protocol UserInfoTaggingProtocol: UserInfoConvertibleProtocol {

    associatedtype NameType

    /// The name of the tagging object
    var name: NameType { get set }

    /// initialize the object with a name
    init(_ name: NameType)
}

/// Protocol for creating tagging object (ie, a tag, a developer, etc) to filter log messages by

public protocol UserInfoTagProtocol: UserInfoTaggingProtocol {
    /// The userInfo key for tag
    static var userInfoKey: String { get }
}

public extension UserInfoTagProtocol {
    /// Dictionary representation compatible with the userInfo parameter of log messages
    var dictionary: [String: Any] {
        return [Self.userInfoKey: name]
    }

    /// Create a Tag object with a name
    public static func name(_ name: NameType) -> Self {
        return Self(name)
    }
    
    /// Generate a userInfo compatible dictionary for the array of names
    public static func names(_ names: String...) -> [String: [String]] {
        var tags: [String] = []
        
        for name in names {
            tags.append(name)
        }
        
        return [Self.userInfoKey: tags]
    }
}

/// Struction for tagging log messages with Tags
public struct Tag: UserInfoTagProtocol {

    /// The name of the tag
    public var name: String


    /// Initialize a Tag object with a name
    public init(_ name: String) {
        self.name = name
    }
    
    /// The userInfo key for tag
    public static var userInfoKey: String {
        return XCGLogger.Constants.userInfoKeyTags
    }
}

/// Struction for tagging log messages with Developers
public struct Dev: UserInfoTagProtocol {

    /// The name of the developer
    public var name: String

    /// Initialize a Dev object with a name
    public init(_ name: String) {
        self.name = name
    }
    
    /// The userInfo key for dev
    public static var userInfoKey: String {
        return XCGLogger.Constants.userInfoKeyDevs
    }

}

/// Overloaded operator to merge userInfo compatible dictionaries together
/// Note: should correctly handle combining single elements of the same key, or an element and an array, but will skip sets
public func |<Key: Any, Value: Any> (lhs: Dictionary<Key, Value>, rhs: Dictionary<Key, Value>) -> Dictionary<Key, Any> {
    var mergedDictionary: Dictionary<Key, Any> = lhs

    rhs.forEach { key, rhsValue in
        guard let lhsValue = lhs[key] else { mergedDictionary[key] = rhsValue; return }
        guard !(rhsValue is Set<AnyHashable>) else { return }
        guard !(lhsValue is Set<AnyHashable>) else { return }

        if let lhsValue = lhsValue as? [Any],
            let rhsValue = rhsValue as? [Any] {
            // array, array -> array
            var mergedArray: [Any] = lhsValue
            mergedArray.append(contentsOf: rhsValue)
            mergedDictionary[key] = mergedArray
        }
        else if let lhsValue = lhsValue as? [Any] {
            // array, item -> array
            var mergedArray: [Any] = lhsValue
            mergedArray.append(rhsValue)
            mergedDictionary[key] = mergedArray
        }
        else if let rhsValue = rhsValue as? [Any] {
            // item, array -> array
            var mergedArray: [Any] = rhsValue
            mergedArray.append(lhsValue)
            mergedDictionary[key] = mergedArray
        }
        else {
            // two items -> array
            mergedDictionary[key] = [lhsValue, rhsValue]
        }
    }

    return mergedDictionary
}

/// Overloaded operator, converts UserInfoTaggingProtocol types to dictionaries and then merges them
public func | <T: UserInfoConvertibleProtocol, U: UserInfoConvertibleProtocol> (lhs: T, rhs: U) -> Dictionary<String, Any> {
    return lhs.dictionary | rhs.dictionary
}

/// Overloaded operator, converts UserInfoTaggingProtocol types to dictionaries and then merges them
public func | <T: UserInfoConvertibleProtocol> (lhs: T, rhs: Dictionary<String, Any>) -> Dictionary<String, Any> {
    return lhs.dictionary | rhs
}

/// Overloaded operator, converts UserInfoTaggingProtocol types to dictionaries and then merges them
public func | <T: UserInfoConvertibleProtocol> (lhs: Dictionary<String, Any>, rhs: T) -> Dictionary<String, Any> {
    return rhs.dictionary | lhs
}

/// Extend UserInfoFilter to be able to use UserInfoTaggingProtocol objects
public extension UserInfoFilter {

    /// Initializer to create an inclusion list of tags to match against
    ///
    /// Note: Only log messages with a specific tag will be logged, all others will be excluded
    ///
    /// - Parameters:
    ///     - tags: Array of UserInfoTaggingProtocol objects to match against.
    ///
    public convenience init<T: UserInfoTaggingProtocol>(includeFrom tags: [T]) where T.NameType == String {
        var names: [String] = []
        for tag in tags {
            names.append(tag.name)
        }

        self.init(includeFrom: names)
    }

    /// Initializer to create an exclusion list of tags to match against
    ///
    /// Note: Log messages with a specific tag will be excluded from logging
    ///
    /// - Parameters:
    ///     - tags: Array of UserInfoTaggingProtocol objects to match against.
    ///
    public convenience init<T: UserInfoTaggingProtocol>(excludeFrom tags: [T]) where T.NameType == String {
        var names: [String] = []
        for tag in tags {
            names.append(tag.name)
        }

        self.init(excludeFrom: names)
    }
}
