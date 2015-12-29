//
//  POSTFactory.swift
//

import Foundation
import CoreData

public class InsertionFactory {

    private static var processors:Dictionary<String, EntityProcessor> = Dictionary<String, EntityProcessor>()

    static func registerProcessor(entityName: String, entityProcessor: EntityProcessor) {
        processors.updateValue(entityProcessor, forKey: entityName)
    }

    static func unregisterProcessor(entityName: String) {
        processors.removeValueForKey(entityName)
    }
//TODO: Can this be rewritten in the for loop to one guard statement?
    static func process(insertions:Set<NSManagedObject>) -> Array<RemoteStoreRequest> {
        var changeRequests:Array<RemoteStoreRequest> = Array<RemoteStoreRequest>()
        for object in insertions {
            guard let entityName = object.entity.name else { break }
            guard let entityProcessor:EntityProcessor = processors[entityName] else { break }
            guard let request = entityProcessor.process(object) else { break }
            changeRequests.append(request)
        }

        return Array<RemoteStoreRequest>()
    }
}