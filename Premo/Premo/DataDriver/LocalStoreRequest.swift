//
//  LocalStoreRequest.swift
//

import Foundation

/*
    The LocalStoreRequest protocol is implemented by a Transaction Partition delegate to manipulate the URL accessed by the partition. Both methods are optional, with the component overrides applied first, followed by the override tokens.
*/
@objc public protocol LocalStoreRequest {
    /**
     Assign an NSURLComponents object to this property to alter the URL used to retrieve local store results.
     
     - Note: While this method will be accessed in a thread-safe manner, any underlying storage should also be made thread-safe.
     */
    optional func localURLComponentOverrides() -> NSURLComponents?

    /**
     Assign a Dictionary of tokens that should alter the URL used to retrieve local store results.
     
     - Note: While this method will be accessed in a thread-safe manner, any underlying storage should also be made thread-safe.
     */
    optional func localStoreOverrideTokens() -> Dictionary<NSObject, AnyObject>?
    
}