//
//  JSONObjectDataConditionerFactory.swift
//

import Foundation
import CoreData

public class JSONObjectDataConditionerFactory {

    private static var objectConditioners:Dictionary<String, JSONObjectConditioner> = Dictionary<String, JSONObjectConditioner>()

    static func registerObjectConditioner(entityName: String, objectConditioner: JSONObjectConditioner) {
        objectConditioners.updateValue(objectConditioner, forKey: entityName)
    }

    static func unregisterObjectConditioner(entityName: String) {
        objectConditioners.removeValueForKey(entityName)
    }

    static func conditionObjects(JSONObjects:Array<Dictionary<NSObject, AnyObject>>, entity:NSEntityDescription) -> Array<Dictionary<NSObject, AnyObject>> {
        var processedJSONObjects:Array<Dictionary<NSObject, AnyObject>> = Array<Dictionary<NSObject, AnyObject>>()
        for object in JSONObjects {
            guard let entityName = entity.name else { processedJSONObjects.append(object); break }
            guard let objectConditioner:JSONObjectConditioner = objectConditioners[entityName] else { processedJSONObjects.append(object); break }
            guard let conditionedObject = objectConditioner.condition(object) else { processedJSONObjects.append(object); break }
            processedJSONObjects.append(conditionedObject)
        }

        return processedJSONObjects
    }
}