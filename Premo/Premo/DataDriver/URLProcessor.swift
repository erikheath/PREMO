//
//  URLProcessor.swift

//

//

import Foundation
import CoreData

protocol URLProcessor {

    func process(changeRequest: RemoteStoreRequest) -> Array<RemoteStoreRequest>
}

public class URLProcessorFactory {

    private static var processors:Dictionary<String, URLProcessor> = Dictionary<String, URLProcessor>()

    static func registerProcessor(entityName: String, entityProcessor: URLProcessor) {
        processors.updateValue(entityProcessor, forKey: entityName)
    }

    static func unregisterProcessor(entityName: String) {
        processors.removeValueForKey(entityName)
    }

    static func processor(entityName: String) -> URLProcessor? {
        return processors[entityName]
    }

}


