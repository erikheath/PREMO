//
//  DataRequestOperation.swift

//

//

import Foundation
import CoreData

public class DataRequestOperation: NSOperation {

    // MARK: - Properties
    private(set) var remoteStoreRequests:Array<NSMutableURLRequest>
    let URLSession:NSURLSession

    // MARK: - Object Lifecycle
    init (session:NSURLSession, requests:Array<RemoteStoreRequest> ) {

        var requestsArray:Array<NSMutableURLRequest> = []

        for request in requests {
            switch request.methodType {

            case .GET:
                requestsArray.append(NSMutableURLRequest(entity: request.entity, property: request.property, predicate: request.predicate, URLOverrides: request.URLOverrides, overrideTokens: request.overrideTokens, destinationID: request.destinationID))

            case .POST:
                let insertionRequest = NSMutableURLRequest(entity: request.entity, property: request.property, predicate: request.predicate, URLOverrides: request.URLOverrides, overrideTokens: request.overrideTokens, destinationID: request.destinationID)
                insertionRequest.HTTPMethod = request.methodType.rawValue
                insertionRequest.HTTPBody = request.methodBody
                requestsArray.append(insertionRequest)

            case .PUT:
                let replaceRequest = NSMutableURLRequest(entity: request.entity, property: request.property, predicate: request.predicate, URLOverrides: request.URLOverrides, overrideTokens: request.overrideTokens, destinationID: request.destinationID)
                replaceRequest.HTTPMethod = request.methodType.rawValue
                replaceRequest.HTTPBody = request.methodBody
                requestsArray.append(replaceRequest)

            case .PATCH:
                let updateRequest = NSMutableURLRequest(entity: request.entity, property: request.property, predicate: request.predicate, URLOverrides: request.URLOverrides, overrideTokens: request.overrideTokens, destinationID: request.destinationID)
                updateRequest.HTTPMethod = request.methodType.rawValue
                updateRequest.HTTPBody = request.methodBody
                requestsArray.append(updateRequest)

            case .DELETE:
                let deleteRequest = NSMutableURLRequest(entity: request.entity, property: request.property, predicate: request.predicate, URLOverrides: request.URLOverrides, overrideTokens: request.overrideTokens, destinationID: request.destinationID)
                deleteRequest.HTTPMethod = request.methodType.rawValue
                deleteRequest.HTTPBody = request.methodBody
                requestsArray.append(deleteRequest)

            }
        }

        self.remoteStoreRequests = requestsArray
        self.URLSession = session

        super.init()
    }

    override public func main() {
        autoreleasepool { () -> () in

            if !self.cancelled {
                do {
                    for request in remoteStoreRequests {
                        let dataTask = try self.URLSession.dataTaskWithRequest(request.resolveURL())
                        dataTask.resume()
                    }
                } catch {
                    let userInfoDict:[String: AnyObject] = [kUnderlyingErrorsArrayKey: [error as NSError]]
                    NSNotificationCenter.defaultCenter().postNotificationName(kErrorNotification, object: nil, userInfo:userInfoDict)
                }
            }
        }
    }

}




