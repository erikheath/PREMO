//
//  DataConditionerOperation.swift
//
//

import CoreData

public class DataConditionerOperation: NSOperation {

    // MARK: Properties

    let parentContext: NSManagedObjectContext
    let responseData: NSData
    let URLRequest: NSURLRequest
    let graphManager: OperationGraphManager
    private var traversedIdentifiers: Array<NSManagedObjectID>


    // MARK: Object Lifecycle

    init (parentContext: NSManagedObjectContext, data: NSData, URLRequest: NSURLRequest, graphManager: OperationGraphManager) {
        self.parentContext = parentContext
        self.responseData = data
        self.URLRequest = URLRequest
        self.graphManager = graphManager
        self.traversedIdentifiers = Array()
        super.init()
    }


    // MARK: Operation Processing Flow

    override public func main() {
        autoreleasepool { () -> () in

            self.parentContext.performBlockAndWait({ () -> Void in
                self.parentContext.reset()
            })

            if let masterContext = self.parentContext.parentContext?.parentContext {
                masterContext.performBlockAndWait({ () -> Void in
                    masterContext.reset()
                })
            }


            processor: do {

                let conditionedInfo:NSDictionary

                guard let targetEntity = self.URLRequest.requestEntity else {
                    throw JSONParserError.missingEntity
                }

                guard let entityUserInfo = targetEntity.userInfo else {
                    throw JSONParserError.missingUserInfoDictionary
                }

                // Does the incoming data need to be conditioned because it is a feed for a property or image binary data?
                if let targetProperty = self.URLRequest.requestPropertyDescription where targetProperty is NSRelationshipDescription && targetProperty.userInfo != nil {
                    conditionedInfo = targetProperty.userInfo!
                } else if let targetProperty = self.URLRequest.requestPropertyDescription where targetProperty is NSAttributeDescription && targetProperty.userInfo?[kRemoteStoreURLType] as? String == kRemoteStoreURLTypeImage {
                    conditionedInfo = targetProperty.userInfo!
                } else if targetEntity.userInfo != nil {
                    conditionedInfo = targetEntity.userInfo!
                } else {
                    throw JSONParserError.missingUserInfoDictionary
                }

                let objectIDArray:Array<NSManagedObjectID>
                do {
                    objectIDArray = try self.processJSONDataStructure(conditionedInfo, targetEntity: targetEntity)
                } catch {
                    throw error
                }

                self.parentContext.performBlockAndWait({ () -> Void in
                    do {
                        try self.parentContext.save()
                    } catch {
                        self.parentContext.reset()
                    }
                })

                self.parentContext.parentContext?.performBlockAndWait({ () -> Void in
                    do {
                        try self.parentContext.parentContext?.save()
                    } catch {
                        // This should never fail, and if an error happens, it is not
                        // recoverable from the data layer
                    }
                })

                var metadata:AnyObject?
                metadata = entityUserInfo[kRemoteStoreJSONMetadataKeyPath] as AnyObject?
                if metadata == nil {
                    metadata = targetEntity.managedObjectModel.entitiesByName[kModelInfoEntity]?.userInfo?[kRemoteStoreJSONMetadataKeyPath] as AnyObject?
                }
                if metadata == nil {
                    metadata = ""
                }

                let notificationInfo:Dictionary<NSObject, AnyObject>? = [kObjectIDsArray:objectIDArray, kRemoteStoreJSONMetadataKeyPath:(metadata as!
                    NSObject)]

                let notification = NSNotification(name: kObjectIDsForRequestNotification, object: nil, userInfo: notificationInfo)

                NSNotificationCenter.defaultCenter().performSelectorOnMainThread("postNotification:", withObject: notification, waitUntilDone: false)

                if let masterContext:NSManagedObjectContext = self.parentContext.parentContext?.parentContext {

                    masterContext.performBlockAndWait({ () -> Void in
                        do {
                            try masterContext.save()
                        } catch {
                            // This should never fail, and if an error happens, it is not
                            // recoverable from the data layer
                        }
                    })

                }

                if self.cancelled == false {
                    // TODO: Set the status to fulfilled

                } else {
                    // TODO: Set the status to expired
                }

            } catch {
                print(error)
            }

        }
    }


    // MARK: Utility Methods

    // Creates a managed object context used for the creation / updating of a target object.
    func objectProcessingContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType:NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
        context.undoManager = nil
        context.parentContext = self.parentContext
        return context
    }

    // Returns an existing or new managed object for an object in the remote store.
    func managedObjectForRemoteStore(valueSource:NSDictionary, entity:NSEntityDescription, context:NSManagedObjectContext, objectID: NSManagedObjectID?) throws -> NSManagedObject {

        do {
            var managedObject:NSManagedObject?

            if let _ = objectID {

                managedObject = context.objectWithID(objectID!)

            } else {

                guard let modelEntityID = (entity.userInfo?[kModelEntityID] as? String),
                    let keyPath:String = entity.userInfo?[kEntityID] as? String,
                    let propertyID:String = valueSource.valueForKey(keyPath) as? String where entity.name != nil else {
                        throw JSONParserError.expectedAttributeValueError
                }

                let request = NSFetchRequest(entityName: entity.name!)
                request.sortDescriptors = [NSSortDescriptor(key: modelEntityID, ascending: false)]

                let leftExpression = NSExpression(forKeyPath: modelEntityID)
                let rightExpression = NSExpression(forConstantValue: propertyID)

                request.predicate = NSComparisonPredicate(leftExpression:leftExpression , rightExpression: rightExpression, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options:NSComparisonPredicateOptions(rawValue: 0))

                let results = try context.executeFetchRequest(request)

                managedObject = (results as NSArray).firstObject as? NSManagedObject

            }

            if let object = managedObject where (entity.userInfo?[kFlushLocalObjectsOnRemoteUpdate] as? Bool) == true {
                context.deleteObject(object)
                managedObject = nil
            }

            if managedObject == nil {
                let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context)
                context.performBlockAndWait({ () -> Void in
                    do {
                        try context.obtainPermanentIDsForObjects([object])
                    } catch {   }
                })
                managedObject = object
            }

            return managedObject!

        } catch {
            throw error
        }

    }

    // MARK: Image Processing


    // MARK: JSON Processing
    func processJSONDataStructure(conditionedInfo:NSDictionary, targetEntity: NSEntityDescription) throws -> Array<NSManagedObjectID>{


        let dataArray:Array<NSDictionary>
        var objectIDArray:Array<NSManagedObjectID> = []

        let response: AnyObject
        do {
            response = try NSJSONSerialization.JSONObjectWithData(self.responseData, options:NSJSONReadingOptions.init(rawValue: 0))
        } catch {
            throw JSONParserError.formatError
        }

        guard let rootKeyPath = conditionedInfo[kJSONRootKeyPath] as? String else {
            throw JSONParserError.expectedAttributeError
        }

        guard let dataStructure:AnyObject? = response.valueForKeyPath(rootKeyPath) ?? response
            else {
                throw JSONParserError.expectedAttributeValueError
        }

        switch dataStructure {

        case is NSDictionary:
            dataArray = [dataStructure as! NSDictionary]

        case is NSArray:
            if (conditionedInfo[kRerootJSONSource] as? NSString)?.boolValue == true {
                guard let JSONRelationshipPath = conditionedInfo[kJSONKeyPath] as? String else { throw JSONParserError.expectedAttributeTypeError }
                let restructure = NSMutableDictionary()
                restructure.setValue(dataStructure, forKey: JSONRelationshipPath)
                dataArray = [NSDictionary(dictionary: restructure)]
            } else {
                dataArray = dataStructure as! Array<NSDictionary>
            }
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        let targetBatchCount:Int

        guard let entityUserInfo = targetEntity.userInfo else {
            throw JSONParserError.missingUserInfoDictionary
        }

        if let count:Int = (entityUserInfo[kContextSaveBatchSize] as? NSString)?.integerValue {
            targetBatchCount = count
        } else if let count:Int = (targetEntity.managedObjectModel.entitiesByName[kModelInfoEntity]?.userInfo?[kContextSaveBatchSize] as? NSString)?.integerValue {
            targetBatchCount = count
        } else {
            targetBatchCount = 1
        }

        var currentBatchCount = 0

        // BEGIN JSON Object FOR LOOP
        for JSONObject:NSDictionary in dataArray {

            var managedObject:NSManagedObject
            let context = self.objectProcessingContext()

            if self.cancelled == false {
                managedObject = try self.managedObjectForRemoteStore(JSONObject, entity: targetEntity, context: context, objectID:self.URLRequest.destinationObjectID)
                do {
                    try self.fulfillManagedObject(managedObject, valueSource: JSONObject, parentRelationship: nil)
                } catch {
                    // If the object is invalid it should be removed from the context.
                    // This usually results from validate being called and an object
                    // missing a required attribute value or relationship. It's important
                    // to set the delete rules properly to avoid polluting the database.
                    context.performBlockAndWait({ () -> Void in
                        context.deleteObject(managedObject)
                    })
                    continue
                }

                var saveError:NSError? = nil

                context.performBlockAndWait({ () -> Void in
                    do {
                        try context.save()
                    } catch {
                        saveError = error as NSError
                    }
                })

                if saveError == nil {
                    objectIDArray.append(managedObject.objectID)
                    currentBatchCount++
                }
            }

            if currentBatchCount == targetBatchCount {
                currentBatchCount = 0
                // Primary Background Context
                self.parentContext.performBlockAndWait({ () -> Void in
                    do {
                        try self.parentContext.save()
                    } catch {
                        // If there is an error saving, reset the context
                        // so that future saves do not error out.
                        self.parentContext.reset()
                    }
                })

                self.parentContext.parentContext?.performBlockAndWait({ () -> Void in
                    do {
                        try self.parentContext.parentContext?.save()
                    } catch {
                        print(error as NSError)
                        // This should never fail, and if an error happens, it is not
                        // recoverable from the data layer
                    }
                })
            }

            if self.cancelled == true {
                break
            }
        }

        // END JSON Object FOR LOOP

        return objectIDArray
    }

    // The main entry point for filling out (fulfilling) a managed object from a JSON representation.
    // Beginning with this method, a recursive stack is created that traverses the relationships of
    // an entity.
    func fulfillManagedObject(managedObject:NSManagedObject, valueSource:NSDictionary, parentRelationship:NSRelationshipDescription?) throws -> Void {

        do {

            // If the object has already been traversed, then simply return to allow processing to continue with untraversed data.
            if self.traversedIdentifiers.contains(managedObject.objectID) {
                return
            } else {
                self.traversedIdentifiers.append(managedObject.objectID)
            }

            try self.fulfillManagedObject(managedObject, attributesValueSource: valueSource)

            try self.fullfilManagedObject(managedObject, parentRelationship: parentRelationship, relationshipsValueSource: valueSource)

            try managedObject.validateForInsert()

        } catch {
            // An error is generated when an object that is constructed does not pass validation. This is usually from the validation methods on managed object.
            throw error
        }

    }

    // This is the entry point for the control flow that fulfills the relationships of an entity. This method support to-one and to-many. Many-to-many relationships are fulfilled implicitly by in the the to-many fulfillment method.
    func fullfilManagedObject(managedObject:NSManagedObject, parentRelationship:NSRelationshipDescription?, relationshipsValueSource valueSource:NSDictionary) throws -> Void {

        do {
            // When processing the relationships, it's necessary to account for an error being thrown that should stop the processing of other relationships. In effect, if a relationship or attribute is required, an error will be thrown.
            for (_,relationship) in managedObject.entity.relationshipsByName where relationship.inverseRelationship != parentRelationship {
                if relationship.toMany == false {
                    try self.fulfillManagedObject(managedObject, toOneRelationship: relationship, valueSource: valueSource)
                } else {
                    try self.fulfillManagedObject(managedObject, toManyRelationship: relationship, valueSource: valueSource)
                }
            }

        } catch {
            // Errors at this level are typically generated by missing attribute values or by object validations on nested relationships. For an object at this level, a missing / non-conformant relationship will be recognized in the calling method.
            throw error
        }
    }

    // This method fulfills an entity's to-one relationship.
    func fulfillManagedObject(managedObject:NSManagedObject, toOneRelationship relationship:NSRelationshipDescription, valueSource:NSDictionary) throws -> Void {

        // Determine if a relationship object exists, i.e. is there one in the local database?
        let relationshipName = relationship.name
        var relationshipObject:NSManagedObject? = (managedObject.valueForKey(relationshipName) as? NSManagedObject)

        // If local objects are supposed to be flushed (deleted) and completely recreated, remove them from the context. Note that this can create problems if the delete rules for an object are not implemented correctly.
        if (relationship.userInfo?[kFlushLocalObjectsOnRemoteUpdate] as? NSString)?.boolValue == true && relationshipObject != nil {
            managedObject.managedObjectContext?.deleteObject(relationshipObject!)
            relationshipObject = nil
        }

        // If the object doesn't yet exist (it isn't in the local store) or it has been flushed, create it.
        if let destinationEntity = relationship.destinationEntity, context = managedObject.managedObjectContext where relationshipObject == nil {
            relationshipObject = NSManagedObject(entity: destinationEntity, insertIntoManagedObjectContext: context)
            context.performBlockAndWait({ () -> Void in
                do {
                    try context.obtainPermanentIDsForObjects([relationshipObject!])
                } catch {   }
            })

        }

        // TODO: Should a to-one relationship be supported that doesn't have an inverse defined? Currently, no, and it will throw an error, effectively stopping traversal for this relationship and anything nested off of this object.
        do {
            guard let relationshipObject = relationshipObject where relationship.inverseRelationship != nil else {
                throw JSONParserError.expectedInverseRelationshipError
            }

            // Begin fulfilling the target of the to-one relatioship by calling into (effectively recursing) the JSON processor entry point.
            try self.fulfillManagedObject(relationshipObject, valueSource: valueSource, parentRelationship: relationship)

            // Validate value will throw an error if the managed object is not internally consistent with the rules set up in the model.
            var x: AnyObject? = relationshipObject as AnyObject?
            try managedObject.validateValue(&x, forKey: relationship.name)

            // The inverse is set automagically
            if managedObject.valueForKey(relationship.name) == nil {
                managedObject.setValue(relationshipObject, forKey: relationship.name)
            }

        } catch {
            // An JSONParserError is usually when something is missing that is integral to processing the JSON, either in the entity or in the JSON data being processed. This is not necessarily an error that should be propagated (thrown) as not all JSON structures may have all of the needed data, even though they can update objects. Put another way, it's possible for an object at this level to have requirements for it's children that are unmet, but for this object to not be required by its parent. Like other errors thrown by validate, this requires getting rid of the object inserted into the context.
            if relationshipObject != nil {
                managedObject.managedObjectContext?.deleteObject(relationshipObject!)
            }

            // Only throw the error if the relationship being fulfilled is required for the calling object.
            if relationship.optional != true {
                throw error
            }
        }
    }

    func processIntegerAttribute(attribute: NSObject) throws -> AnyObject? {
        var attributeValue:AnyObject?

        switch attribute {

        case is String:
            attributeValue = NSNumber(integer: (attribute as! NSString).integerValue)
        case is NSNull:
            attributeValue = nil
        case is NSNumber:
            attributeValue = attribute
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        return attributeValue
    }

    func processDecimalAttribute(attribute: NSObject) throws -> AnyObject? {
        var attributeValue:AnyObject?

        switch attribute {

        case is String:
            attributeValue = NSDecimalNumber(string: attribute as? String)
        case is NSNumber:
            attributeValue = NSDecimalNumber(decimal: (attribute as! NSNumber).decimalValue)
        case is NSNull:
            attributeValue = nil
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        return attributeValue
    }

    func processDoubleAttribute(attribute: NSObject) throws -> AnyObject? {
        var attributeValue:AnyObject?

        switch attribute {

        case is String:
            attributeValue = NSNumber(double: ((attribute as! NSString).doubleValue))
        case is NSNull:
            attributeValue = nil
        case is NSNumber:
            attributeValue = attribute
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        return attributeValue
    }

    func processFloatAttribute(attribute: NSObject) throws -> AnyObject? {
        var attributeValue:AnyObject?

        switch attribute {

        case is String:
            attributeValue = NSNumber(float: ((attribute as! NSString).floatValue))
        case is NSNull:
            attributeValue = nil
        case is NSNumber:
            attributeValue = attribute
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        return attributeValue
    }

    func processStringAttribute(attribute: NSObject) throws -> AnyObject? {
        var attributeValue:AnyObject?

        switch attribute {

        case is NSNumber:
            attributeValue = attribute.description
        case is NSNull:
            attributeValue = nil
        case is String:
            attributeValue = attribute
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        return attributeValue
    }

    func processBooleanAttribute(attribute: NSObject) throws -> AnyObject? {
        var attributeValue:AnyObject?

        switch attribute {

        case is String:
            attributeValue = NSNumber(bool: (attribute as! NSString).boolValue)
        case is NSNull:
            attributeValue = nil
        case is NSNumber:
            attributeValue = attribute
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        return attributeValue
    }

    func processDateAttribute(attribute: NSObject) throws -> AnyObject? {
        var attributeValue:AnyObject?

        switch attribute {

        case is String:
            let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = enUSPOSIXLocale
            dateFormatter.dateFormat = "yyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            if let convertedAttribute = dateFormatter.dateFromString(attribute as! String) {
                attributeValue = convertedAttribute
            } else {
                throw JSONParserError.expectedAttributeTypeError
            }
        case is NSNull:
            attributeValue = nil
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        return attributeValue
    }

    func processTransformableAttribute(attribute: NSObject, attributeDescription: NSAttributeDescription, managedObject: NSManagedObject) throws -> AnyObject? {
        var attributeValue:AnyObject?

        switch attribute {

        case is String:
            if let convertedAttribute = NSURL(string: attribute as! String) where (attributeDescription.userInfo?[kRemoteStoreURLType] as? NSString)?.boolValue == true {
                attributeValue = convertedAttribute
                // If the item should be downloaded, spawn an operation using a change request generated by a custom processor. A processor must be registered for the entity by the app.
                guard let targetEntityName = attributeDescription.userInfo?[kDownloadResourceTargetEntity] as? String where attributeDescription.userInfo?[kDownloadResourceOption] as? String == kDownloadResourceOnCreate else { break }
                guard let targetEntity = NSEntityDescription.entityForName(targetEntityName, inManagedObjectContext: self.parentContext) else { break }
                var targetProperty: NSPropertyDescription? = nil
                if let targetPropertyName = attributeDescription.userInfo?[kDownloadResourceTargetProperty] as? String {
                    targetProperty = targetEntity.propertiesByName[targetPropertyName]
                }
                var targetObjectID: NSManagedObjectID? = nil
                if targetProperty != nil { targetObjectID = managedObject.objectID }
                let URLOverrides = NSURLComponents(URL: convertedAttribute, resolvingAgainstBaseURL: false)
                let changeRequest = RemoteStoreRequest(entity: targetEntity, property: targetProperty, predicate: nil, URLOverrides: URLOverrides, overrideTokens: nil, methodType: RemoteStoreRequest.RequestType.GET, methodBody: nil, destinationID: targetObjectID)
                if let processor = URLProcessorFactory.processor(targetEntityName) {
                    let changeRequestArray = processor.process(changeRequest) // This is where customiation can occur
                    if changeRequestArray.count > 0 {
                        self.graphManager.requestNetworkStoreOperations(changeRequestArray)
                    }
                } else {

                    self.graphManager.requestNetworkStoreOperations([changeRequest])
                }

            }
        case is NSNull:
            attributeValue = nil
        default:
            throw JSONParserError.expectedAttributeTypeError
        }

        return attributeValue
    }

    // This method fulfills an objects attribute (property) values. If the incoming value is null or the empty string, this means the key is in the dictionary and the property will be set to nil in the local store. If the key returns nil, this means the key is not in the dictionary and the local property will not be set.
    func fulfillManagedObject(managedObject:NSManagedObject, attributesValueSource:NSDictionary) throws -> Void {

        guard let attributes:Dictionary<String, NSAttributeDescription> = managedObject.entity.attributesByName as Dictionary<String, NSAttributeDescription> else {
            throw JSONParserError.expectedAttributeTypeError
        }

        for (attributeKey, object) in attributes {
            // If the key is in the response but has no data, this effectively sets the property to nil / null. Numbers without values are converted to the default (0) by NSString. If a property is null, it will be set to nil.

            var attributeValue:AnyObject?

            if let key = object.userInfo?[kJSONKeyPath] as? String {

                if let valueToCheck:NSObject = (attributesValueSource as NSDictionary).valueForKeyPath(key) as? NSObject {

                    switch object.attributeType {

                    case .Integer16AttributeType, .Integer32AttributeType, .Integer64AttributeType:
                        try attributeValue = self.processIntegerAttribute(valueToCheck)

                    case .DecimalAttributeType:
                        try attributeValue = self.processDecimalAttribute(valueToCheck)

                    case .DoubleAttributeType:
                        try attributeValue = self.processDoubleAttribute(valueToCheck)

                    case .FloatAttributeType:
                        try attributeValue = self.processFloatAttribute(valueToCheck)

                    case .StringAttributeType:
                        try attributeValue = self.processStringAttribute(valueToCheck)

                    case .BooleanAttributeType:
                        try attributeValue = self.processBooleanAttribute(valueToCheck)

                    case .DateAttributeType:
                        try attributeValue = self.processDateAttribute(valueToCheck)

                    case .TransformableAttributeType:
                        try attributeValue = self.processTransformableAttribute(valueToCheck, attributeDescription: object, managedObject: managedObject)

                    case .ObjectIDAttributeType, .BinaryDataAttributeType, .UndefinedAttributeType:
                        break

                    }
                }
            } else {
                // If an object descends from a base entity with a fetch expiration, then fill in the expiration time.

                let generateFetchExpiration = { (timeInterval:AnyObject) -> NSDate in

                    let intervalAsDouble: Double
                    let expiration: NSDate

                    switch timeInterval {

                    case is String:
                        intervalAsDouble = (timeInterval as! NSString).doubleValue
                        expiration = NSDate().dateByAddingTimeInterval(intervalAsDouble)

                    case is NSNumber:
                        intervalAsDouble = (timeInterval as! NSNumber).doubleValue
                        expiration = NSDate().dateByAddingTimeInterval(intervalAsDouble)

                    default:
                        expiration = NSDate()
                    }

                    return expiration

                }

                if attributeKey == "fetchExpiration" {
                    attributeValue = NSDate() // Set the default
                    var currentEntity: NSEntityDescription? = object.entity
                    repeat {
                        if let timeInterval = currentEntity?.userInfo?[kExpirationInterval] {
                            attributeValue = generateFetchExpiration(timeInterval)
                            break
                        } else {
                            currentEntity = currentEntity?.superentity
                        }
                    } while currentEntity != nil
                }
            }

            do {
                if let _ = attributeValue {
                    // Validate and set the value that has been constructed, throwing any error.
                    try managedObject.validateValue(&attributeValue, forKeyPath: attributeKey)
                    managedObject.setValue(attributeValue, forKey: attributeKey)
                }
            } catch {
                throw error
            }

        }
    }

    // The objects in the relationship may be an unordered, unkeyed collection - a set.
    func processMutableSet(relationshipSet: NSMutableSet,  relationship: NSRelationshipDescription, managedObject: NSManagedObject, dataStructure: [Dictionary<NSObject, AnyObject>]) throws -> Void {

        guard let context = managedObject.managedObjectContext else { throw DataLayerError.genericError }

        // The objects in the set may need to be flushed, depending on the settings in the model.
        if (relationship.userInfo?[kFlushLocalObjectsOnRemoteUpdate] as! NSString).boolValue == true {
            for objectToDelete in relationshipSet {
                if let objectToDelete = objectToDelete as? NSManagedObject {
                    objectToDelete.managedObjectContext?.performBlockAndWait({ () -> Void in
                        objectToDelete.managedObjectContext?.deleteObject(objectToDelete)
                    })
                }
            }

        }

        // These keys are what enable a search through the incoming data - kEntityID - and the local store objects in the relationshipSet - kModelEntityID. Without them, no match can be made to local objects. This effectively prevents the data from being written locally. This is a processing error, however, if the relationship is marked as optional, it will not stop processing of the current object. This method should never be entered if the relationship doesn't exist in the model.

        guard let remoteEntityIDKeyPath = relationship.destinationEntity?.userInfo?[kEntityID] as? String,
            let modelEntityIDKeyPath = relationship.destinationEntity?.userInfo?[kModelEntityID] as? String else {
                throw JSONParserError.expectedAttributeValueError
        }

        var objectsNeedingPermanentIDs : [NSManagedObject] = []
        dataProcessor: for sourceDictionary in dataStructure {

            var relationshipObject:NSManagedObject?

            // Keep a list of object ids that have already been hit??

            // Search for a local store object that matches the object described in the incoming dataStructure
            for object in relationshipSet {
                if let object = object as? NSManagedObject where (object.valueForKey(modelEntityIDKeyPath) as? NSString)?.description == (sourceDictionary[remoteEntityIDKeyPath] as? NSString)?.description {
                    break
                }
            }

            // Create the relationship object if needed.
            if let entity = relationship.destinationEntity where relationshipObject == nil {
                relationshipObject = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context)
                if let _ = relationshipObject {
                    objectsNeedingPermanentIDs.append(relationshipObject!)
                }
            }


            do {
                // The current system requires inverse relationships, therefore it is an error not to have one for any defined relationship.
                guard let relationshipObject = relationshipObject where relationship.inverseRelationship != nil else {
                    throw JSONParserError.expectedInverseRelationshipError
                }

                // Fulfill the object that has been created for the relationship set. If an error is thrown, it means that a requirement for the object has not been met and the relationship cannot be fulfilled.
                try self.fulfillManagedObject(relationshipObject, valueSource: sourceDictionary as NSDictionary, parentRelationship: relationship)
                relationshipSet.addObject(relationshipObject)
            } catch {
                throw error
            }
        }
        // obtain the permanent IDs all at once, for efficency
        if 0 < objectsNeedingPermanentIDs.count {
            context.performBlockAndWait({ () -> Void in
                do {
                    try context.obtainPermanentIDsForObjects(objectsNeedingPermanentIDs)
                } catch {  }
            })
        }

        do {
            var x: AnyObject? = relationshipSet as AnyObject?
            try managedObject.validateValue(&x, forKey: relationship.name)
            for relationshipObject in relationshipSet {
                relationshipObject.setValue(managedObject, forKey: relationship.inverseRelationship!.name)
            }
            managedObject.setValue(relationshipSet, forKey: relationship.name)

        } catch {
            if relationship.optional != true {
                throw error
            }
        }



    }

    // The objects in a relationship may be ordered, requiring processing of an ordered set. If there is an error processing any of the items in the set,
    func processOrderedSet(relationshipSet: NSMutableOrderedSet,  relationship: NSRelationshipDescription, managedObject: NSManagedObject, dataStructure: [Dictionary<NSObject, AnyObject>]) throws -> Void {

        guard let context = managedObject.managedObjectContext else { throw DataLayerError.genericError }

        // The objects in the set may need to be flushed, depending on the settings in the model.
        if let flushPolicy = relationship.userInfo?[kFlushLocalObjectsOnRemoteUpdate] as? NSString {
            if true == flushPolicy.boolValue {
                for objectToDelete in relationshipSet {
                    if let objectToDelete = objectToDelete as? NSManagedObject {
                        objectToDelete.managedObjectContext?.performBlockAndWait({ () -> Void in
                            objectToDelete.managedObjectContext?.deleteObject(objectToDelete)
                        })
                    }
                }

            }
        }

        // These keys are what enable a search through the incoming data - kEntityID - and the local store objects in the relationshipSet - kModelEntityID. Without them, no match can be made to local objects. This effectively prevents the data from being written locally. This is a processing error, however, if the relationship is marked as optional, it will not stop processing of the current object. This method should never be entered if the relationship doesn't exist in the model.

        guard let remoteEntityIDKeyPath = relationship.destinationEntity?.userInfo?[kEntityID] as? String,
            let modelEntityIDKeyPath = relationship.destinationEntity?.userInfo?[kModelEntityID] as? String else {
                throw JSONParserError.expectedAttributeValueError
        }

        dataProcessor: for sourceDictionary in dataStructure {

            var relationshipObject:NSManagedObject?

            // Search for a local store object that matches the object described in the incoming dataStructure
            for object in relationshipSet {
                if let object = object as? NSManagedObject where (object.valueForKey(modelEntityIDKeyPath) as? NSString)?.description == (sourceDictionary[remoteEntityIDKeyPath] as? NSString)?.description {
                    relationshipObject = object
                    break
                }
            }

            // Create the relationship object if needed.
            if let entity = relationship.destinationEntity where relationshipObject == nil {
                relationshipObject = NSManagedObject(entity: entity, insertIntoManagedObjectContext: context)
                if let _ = relationshipObject {
                    context.performBlockAndWait({ () -> Void in
                        do {
                            try context.obtainPermanentIDsForObjects([relationshipObject!])
                        } catch { } // TODO: FILL IN
                    })
                }
            }

            do {
                // The current system requires inverse relationships, therefore it is an error not to have one for any defined relationship.
                guard let relationshipObject = relationshipObject where relationship.inverseRelationship != nil else {
                    throw JSONParserError.expectedInverseRelationshipError
                }

                // Fulfill the object that has been created for the relationship set. If an error is thrown, it means that a requirement for the object has not been met and the relationship cannot be fulfilled.
                try self.fulfillManagedObject(relationshipObject, valueSource: sourceDictionary as NSDictionary, parentRelationship: relationship)
                relationshipSet.addObject(relationshipObject)
            } catch {
                throw error
            }
        }

        do {
            var x: AnyObject? = relationshipSet as AnyObject?
            try managedObject.validateValue(&x, forKey: relationship.name)
            for relationshipObject in relationshipSet {
                if relationship.inverseRelationship?.toMany == true {
                    if let testSet = relationshipObject.valueForKey(relationship.inverseRelationship!.name) as? NSObject {
                        switch testSet {
                        case is NSSet:
                            let inverseSet = NSMutableSet(set: testSet as! Set<NSObject>)
                            inverseSet.addObject(managedObject)
                            relationshipObject.setValue(NSSet(set: inverseSet), forKey: relationship.inverseRelationship!.name)
                        case is NSOrderedSet:
                            let inverseSet = NSMutableOrderedSet(orderedSet: testSet as! NSOrderedSet)
                            inverseSet.addObject(managedObject)
                            relationshipObject.setValue(NSOrderedSet(orderedSet: inverseSet), forKey: relationship.inverseRelationship!.name)
                        default:
                            break
                        }
                    }
                } else if relationship.inverseRelationship?.toMany == false {
                    relationshipObject.setValue(managedObject, forKey: relationship.inverseRelationship!.name)
                }
            }
            managedObject.setValue(relationshipSet, forKey: relationship.name)

        } catch {
            if relationship.optional != true {
                throw error
            }
        }

    }

    // This is the entry point for fulfilling a to-many and a many-to-many relationship. An error thrown by this method means that a requirement for the managedObject in regards to the to-many or many-to-many relationship has not been met. If the relationship is optional, then this method will not throw an error nor will it propagate an underlying error from one of its children (in effect, the error doesn't matter, even if it does).
    func fulfillManagedObject(managedObject: NSManagedObject, toManyRelationship relationship: NSRelationshipDescription, valueSource: NSDictionary) throws -> Void {
        
        do {
            guard let rootKeyPath = relationship.destinationEntity?.userInfo?[kJSONRootKeyPath] as? String, let dataStructure = valueSource.valueForKeyPath(rootKeyPath) as? [Dictionary<NSObject, AnyObject>],
                let relationshipSet = managedObject.valueForKey(relationship.name) else {
                    throw JSONParserError.expectedAttributeValueError
            }
            do {
                switch relationshipSet {
                case is NSSet:
                    try self.processMutableSet(NSMutableSet(set: relationshipSet as! NSSet), relationship: relationship, managedObject: managedObject, dataStructure:dataStructure)
                    
                case is NSOrderedSet:
                    try self.processOrderedSet(NSMutableOrderedSet(orderedSet: relationshipSet as! NSOrderedSet), relationship: relationship, managedObject: managedObject, dataStructure:dataStructure)
                default:
                    throw JSONParserError.expectedAttributeTypeError
                }
                
            }
        } catch {
            // An JSONParserError is usually when something is missing that is integral to processing the JSON, either in the entity or in the JSON data being processed. This is not necessarily an error that should be propagated (thrown) as not all JSON structures may have all of the needed data, even though they can update objects. Put another way, it's possible for an object at this level to have requirements for it's children that are unmet, but for this object to not be required by its parent. Like other errors thrown by validate, this requires getting rid of the object inserted into the context, though that is done in the set processing methods.
            
            // Only throw the error if the relationship being fulfilled is required for the calling object.
            if relationship.optional != true {
                throw error
            }
            
        }
    }
    
}