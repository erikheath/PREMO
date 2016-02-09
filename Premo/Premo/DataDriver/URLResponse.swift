//
//  URLResponse.swift
//


///////// DELETE THIS FILE ////////////

/*
 This file will be removed as it will no longer be necessary to register processors at the stack level. Instead, you can set a delegate for a session at the stack level and at the transaction level.
*/

import Foundation
import CoreData

protocol URLResponse {
    func process(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL, backgroundContext: NSManagedObjectContext) -> NSOperation
}

public class URLResponseFactory {

    private static var processors:Dictionary<String, Dictionary<String, URLResponse>> = Dictionary<String, Dictionary<String, URLResponse>>()

    static func registerProcessor(entityName: String, entityProcessor: URLResponse, stackID: String) {
        processors.updateValue([entityName: entityProcessor], forKey: stackID)
    }

    static func unregisterProcessor(entityName: String) {
        processors.removeValueForKey(entityName)
    }

    static func processor(entityName: String, stackID: String) -> URLResponse? {
        return processors[stackID]?[entityName]
    }

}
