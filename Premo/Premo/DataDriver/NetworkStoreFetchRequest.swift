//
//  NetworkStoreFetchRequest.swift
//

import CoreData

public class NetworkStoreFetchRequest:NSFetchRequest, NetworkStoreRequest {

    /**
     Assign an NSURLOverrideComponents object to this property to alter the URL used to retrieve network store results.
     */
    public var networkStoreURLOverrides: NSURLComponents?

    /**
     Assign a Dictionary of tokens that should alter the URL used to retrieve network store results.
     */
    public var networkStoreOverrideTokens: Dictionary<NSObject, AnyObject>?

    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let newRequest = super.copyWithZone(zone)
        guard let request = newRequest as? NetworkStoreFetchRequest else { return newRequest }

        if let overrides = self.networkStoreURLOverrides?.copy() as? NSURLComponents {
            request.networkStoreURLOverrides = overrides
        }

        request.networkStoreOverrideTokens = self.networkStoreOverrideTokens
        
        return request
    }

    
}

