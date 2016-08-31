//
//  HelperFunctions.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

func extractTypeName(_ someObject: Any) -> String {
    return (someObject is Any.Type) ? "\(someObject)" : "\(type(of: someObject))"
}
