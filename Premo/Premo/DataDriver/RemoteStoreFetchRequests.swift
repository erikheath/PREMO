//
//  RemoteStoreFetchRequests.swift
//

import CoreData

public protocol RemoteStoreFetch: NSObjectProtocol {
    var transactionDelegate: AnyObject? { get set }
    var transactionCompletionHandler: (Void -> Void)? { get set }
    var transactionUserInfo: [NSObject: AnyObject]? { get set }
}

public class RemoteStoreFetchRequest:NSFetchRequest, RemoteStoreFetch {

    public var transactionDelegate: AnyObject? = nil
    public var transactionCompletionHandler: (Void -> Void)? = nil
    public var transactionUserInfo:[NSObject: AnyObject]? = nil

    override public func copyWithZone(zone: NSZone) -> AnyObject {

        let newRequest = super.copyWithZone(zone)
        guard let request = newRequest as? RemoteStoreFetchRequest else { return newRequest }
        request.transactionDelegate = transactionDelegate
        request.transactionCompletionHandler = transactionCompletionHandler
        request.transactionUserInfo = transactionUserInfo

        return request
    }

}

public class RemoteStoreAsynchronousFetchRequest:NSAsynchronousFetchRequest, RemoteStoreFetch {

    public var transactionDelegate: AnyObject? = nil
    public var transactionCompletionHandler: (Void -> Void)? = nil
    public var transactionUserInfo:[NSObject: AnyObject]? = nil

    override public func copyWithZone(zone: NSZone) -> AnyObject {

        let newRequest = super.copyWithZone(zone)
        guard let request = newRequest as? RemoteStoreAsynchronousFetchRequest else { return newRequest }
        request.transactionDelegate = transactionDelegate
        request.transactionCompletionHandler = transactionCompletionHandler
        request.transactionUserInfo = transactionUserInfo

        return request
    }
    
}
