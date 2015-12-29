//
//  PUTFactory.swift
//

import Foundation
import CoreData

public class UpdateFactory {

    private static var processors:Dictionary<String, EntityProcessor> = Dictionary<String, EntityProcessor>()

    static func registerProcessor(entityName: String, entityProcessor: EntityProcessor) -> Void {
        processors.updateValue(entityProcessor, forKey: entityName)
    }

    static func unregisterProcessor(entityName: String) -> Void {
        processors.removeValueForKey(entityName)
    }

    static func process(updates:Set<NSManagedObject>) -> Array<RemoteStoreRequest> {
        var changeRequests:Array<RemoteStoreRequest> = Array<RemoteStoreRequest>()
        for object in updates {
            guard let entityName = object.entity.name else { break }
            guard let entityProcessor:EntityProcessor = processors[entityName] else { break }
            guard let request = entityProcessor.process(object) else { break }
            changeRequests.append(request)
        }

        return Array<RemoteStoreRequest>()
    }
}