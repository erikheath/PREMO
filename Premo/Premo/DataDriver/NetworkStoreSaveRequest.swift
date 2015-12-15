//
//  NetworkStoreSaveRequest.swift
//

import CoreData

public class NetworkStoreSaveRequest:NSSaveChangesRequest, NetworkStoreRequest {

    /**
     Assign an NSURLOverrideComponents object to this property to alter the URL used to retrieve network store results.
     */
    public var networkStoreURLOverrides: NSURLComponents?

    /**
     Assign a Dictionary of tokens that should alter the URL used to retrieve network store results.
     */
    public var networkStoreOverrideTokens: Dictionary<NSObject, AnyObject>?

    /**
     This method preserves the added properties of the subclass when copying.
    */
    override public func copyWithZone(zone: NSZone) -> AnyObject {
        let newRequest = super.copyWithZone(zone)
        guard let request = newRequest as? NetworkStoreSaveRequest else { return newRequest }

        if let overrides = self.networkStoreURLOverrides?.copy() as? NSURLComponents {
            request.networkStoreURLOverrides = overrides
        }

        request.networkStoreOverrideTokens = self.networkStoreOverrideTokens
        
        return request
    }

    
}
