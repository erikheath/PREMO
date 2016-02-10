//
//  NetworkStoreRequest.swift
//


import Foundation

/*
The NetworkStoreRequest protocol is implemented by a Transaction Partition delegate to manipulate the URL accessed by the partition. Both methods are optional, with the component overrides applied first, followed by the override tokens.
*/
@objc public protocol NetworkStoreRequest {

    /**
     Assign an NSURLComponents object to this property to alter the URL used to retrieve network store results.

     - Note: While this method will be accessed in a thread-safe manner, any underlying storage should also be made thread-safe.
     */
    optional func networkURLComponentOverrides() -> NSURLComponents?

    /**
     Assign a Dictionary of tokens that should alter the URL used to retrieve network store results.

     - Note: While this method will be accessed in a thread-safe manner, any underlying storage should also be made thread-safe.
     */
    optional func networkURLOverrideTokens() -> Dictionary<NSObject, AnyObject>?

}
