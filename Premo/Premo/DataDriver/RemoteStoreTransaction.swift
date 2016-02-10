//
//  RemoteStoreTransaction.swift
//

import CoreData

public class RemoteStoreTransaction: GroupOperation {

    requestProcessor: do {

    if let request = request as? RemoteStoreFetchRequest  {
    var keyToUpdate:NSDate? = nil

    // Has this request already been made and are the results still valid?
    for (key, value) in fetchRequests {
    if request.entity! == value.entity && request.predicate?.description == value.predicateString {
    if value.status == FulfillmentStatus.pending {
    break requestProcessor
    } else if key.compare(NSDate()) != NSComparisonResult.OrderedDescending {
    keyToUpdate = key
    break
    } else {
    break requestProcessor
    }
    }
    }

    // Update the ttl for the expried key
    if keyToUpdate != nil {
    var timeToLive:Double = 0.0
    fetchRequests.removeValueForKey(keyToUpdate!)
    if request.entity!.userInfo?[kTimeToLive] != nil && request.entity!.userInfo?[kTimeToLive] is String {
    timeToLive = (request.entity!.userInfo![kTimeToLive] as? NSString)!.doubleValue
    }
    keyToUpdate = NSDate(timeIntervalSinceNow: timeToLive)
    fetchRequests.updateValue((request.entity!, request.predicate!.description, FulfillmentStatus.pending), forKey: keyToUpdate!)
    }

    // if it's expired or doesn't exist, rerequest it.
    let overrideComponents:NSURLComponents? = context.userInfo[kOverrideComponents] as? NSURLComponents
    let overrideTokens:Dictionary<NSObject, AnyObject>? = context.userInfo[kOverrideTokens] as? Dictionary<NSObject, AnyObject>
    guard let requestEntity = request.entity as NSEntityDescription! else { break requestProcessor }
    let changeRequest = RemoteStoreRequest(entity: requestEntity, property: nil, predicate: request.predicate, URLOverrides: overrideComponents, overrideTokens: overrideTokens, methodType: .GET, methodBody: nil, destinationID: nil)
    self.operationGraphManager.requestNetworkStoreOperations([changeRequest])


    } else if let request = request as? NetworkStoreSaveRequest {
    saveRequests: do {
    guard let stackID = self.dataManager?.stackID else { break saveRequests }
    var changes:Array<RemoteStoreRequest> = []
    if let insertedObjects = request.insertedObjects {
    changes.appendContentsOf(InsertionFactory.process(insertedObjects, stackID: stackID))
    }
    if let updatedObjects = request.updatedObjects {
    changes.appendContentsOf(UpdateFactory.process(updatedObjects, stackID: stackID))
    }
    if let deletedObjects = request.deletedObjects {
    changes.appendContentsOf(DeletionFactory.process(deletedObjects, stackID: stackID))
    }
    self.operationGraphManager.requestNetworkStoreOperations(changes)
    }
    }

    }


}
