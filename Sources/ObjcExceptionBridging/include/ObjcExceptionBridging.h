//
//  ObjcExceptionBridging.h
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Wade Tregaskis on 21/11/16.
//  Copyright © 2016 Wade Tregaskis.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

#import <Foundation/Foundation.h>


//! Project version number for ObjcExceptionBridging.
FOUNDATION_EXPORT double ObjcExceptionBridgingVersionNumber;

//! Project version string for ObjcExceptionBridging.
FOUNDATION_EXPORT const unsigned char ObjcExceptionBridgingVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <ObjcExceptionBridging/PublicHeader.h>

/**
 Execute Swift code that could generate an Objective-C exception in here to catch and handle it gracefully (ie don't crash)

 @param tryBlock Block/Closure to execute that could thrown an Objective-C exception
 @param catchBlock Block/Closure to use if an exception is thrown in the tryBlock
 @param finallyBlock Block/Closure to execute after the tryBlock (or catchBlock if an exception was thrown)

 @note Loosely based on the code here: https://stackoverflow.com/a/35003095/144857 and here: https://github.com/williamFalcon/SwiftTryCatch
 */
NS_INLINE void _try(void(^_Nonnull tryBlock)(void), void(^_Nonnull catchBlock)(NSException* _Nonnull exception), void(^_Nonnull finallyBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException* exception) {
        catchBlock(exception);
    }
    @finally {
        finallyBlock();
    }
}

/**
 Throw an Objective-C exception

 @param exception NSException object to throw

 @note Loosely based on the code here: https://github.com/williamFalcon/SwiftTryCatch
 */
NS_INLINE void _throw(NSException* _Nonnull exception)
{
    @throw exception;
}

