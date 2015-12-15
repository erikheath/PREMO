//
//  URLResponse.swift

//

//

import Foundation
import CoreData

protocol URLResponse {
    func process(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL, backgroundContext: NSManagedObjectContext) -> NSOperation
}

public class URLResponseFactory {

    private static var processors:Dictionary<String, URLResponse> = Dictionary<String, URLResponse>()

    static func registerProcessor(entityName: String, entityProcessor: URLResponse) {
        processors.updateValue(entityProcessor, forKey: entityName)
    }

    static func unregisterProcessor(entityName: String) {
        processors.removeValueForKey(entityName)
    }

    static func processor(entityName: String) -> URLResponse? {
        return processors[entityName]
    }

}
