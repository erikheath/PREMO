//
//  PersistentStoreCoordinator.swift
//

import CoreData

/**
 The PersistentStoreCoordinator object is a subclass of NSPersistentStoreCoordinator that has been adapted to provide network store retrieval capabilities when requesting data.
*/
public class PersistentStoreCoordinator: NSPersistentStoreCoordinator {

    /**
     The parent data manager the coordinator supports.
    */
    weak var dataManager: DataLayer?

    /**
     The coordinator maintains a transaction manager
     */
    lazy private(set) var transactionManager: RemoteStoreTransactionManager? = {
        guard let dataManager = self.dataManager where dataManager.stackType == .Passthrough else {
            return RemoteStoreTransactionManager(coordinator: self)
        }
        return RemoteStoreTransactionManager(parentContext:dataManager.mainContext)
    }()

    // MARK: Conditional Processing

    /**
     The override of the execute request method is used to insert conditional processing for network based requests. See the documentation for the parent class for a complete explanation of this method external to the changes made in this override.
    */
    override public func executeRequest(request: NSPersistentStoreRequest, withContext context: NSManagedObjectContext) throws -> AnyObject {
        transactionManager?.processRequest(request)
        return try super.executeRequest(request, withContext: context)

    }

    
}


