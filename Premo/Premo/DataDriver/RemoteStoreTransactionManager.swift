//
//  RemoteStoreTransactionManager.swift
//

import CoreData

public final class RemoteStoreTransactionManager: NSObject {

    let transactionQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()
    weak var delegate: NSObjectProtocol?
    var managedObjectContext: NSManagedObjectContext

    /**
     The fetch requests dictionary contains all of the requests processed by the transaction manager.
     */
     /*
     TODO: Make thread safe
     This may be written to and read from on multiple threads, so it should be thread-safe.
     */
    var requests:Dictionary<NSDate, (entity: NSEntityDescription, predicateString: String?, status: FulfillmentStatus)> = Dictionary()
    

    public init(parentContext: NSManagedObjectContext) {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = parentContext
        managedObjectContext.undoManager = nil
        managedObjectContext.name = "transactionManagerContext"
        self.managedObjectContext = managedObjectContext
        super.init()
    }

    public init(coordinator: NSPersistentStoreCoordinator) {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        managedObjectContext.undoManager = nil
        managedObjectContext.name = "transactionManagerContext"
        self.managedObjectContext = managedObjectContext
        super.init()
    }

    public func processRequest(request: NSPersistentStoreRequest) -> Void {
        // Add an operation to the queue that will evaluate the request and spawn the appropriate sub-operations.
    }

}

extension RemoteStoreTransactionManager: OperationQueueDelegate {

    func operationQueue(operationQueue: OperationQueue, willAddOperation operation: NSOperation) -> Void {

    }

    func operationQueue(operationQueue: OperationQueue, operationDidFinish operation: NSOperation, withErrors errors: [NSError]) -> Void {

    }
}

