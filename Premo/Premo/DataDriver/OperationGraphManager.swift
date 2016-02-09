//
//  OperationGraphManager.swift
//

//////////////// DELETE THIS FILE /////////////////

/* 
 This file will be broken apart to fill out the NSR Manager Queue, NSR Transaction, and other components of the remodeled system.
*/


import CoreData

public class OperationGraphManager: NSOperation, NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate  {

    // MARK : Properties

    let URLConfiguration: NSURLSessionConfiguration = {
        return NSURLSessionConfiguration.ephemeralSessionConfiguration()
        }()

    let dataRequestQueue: NSOperationQueue = {
        let opQueue = NSOperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        opQueue.name = "com.datadriverlayer.datarequestqueue"

        return opQueue
        }()

    let dataProcessingQueue: NSOperationQueue = {
        let opQueue = NSOperationQueue()
        opQueue.maxConcurrentOperationCount = 1
        opQueue.name = "com.datadriverlayer.dataprocessingqueue"

        return opQueue
        }()

    private(set) var coordinator: PersistentStoreCoordinator

    let changeRequests: Array<RemoteStoreRequest>

    var pendingOperations: Bool = false


    // MARK: Post Init Properties

    var URLSession: NSURLSession {
        get {
            return NSURLSession(configuration: self.URLConfiguration, delegate: self, delegateQueue:nil)
        }
    }

    // MARK: Object Life-Cycle

    init (coordinator:PersistentStoreCoordinator, changeRequests: Array<RemoteStoreRequest>) {
        self.coordinator = coordinator
        self.changeRequests = changeRequests
        super.init()
    }


    // MARK: Operation Management

    override public func main() -> Void {

        let operation = DataRequestOperation(session: self.URLSession, requests: self.changeRequests)
        self.dataRequestQueue.addOperation(operation)

        self.pendingOperations = true

        while self.pendingOperations == true { } // block until the operation is marked as complete

    }

//    func requestNetworkStoreOperations(changeRequests:Array<RemoteStoreRequest>) {
//    }


    // MARK: NSURLSessionDelegate
    // TODO: Add kDataRequestErrorNotification

    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        if let wrappedError: NSError = error {
            let userInfoDict:[String: AnyObject] = [kUnderlyingErrorsArrayKey: [wrappedError]]
            NSNotificationCenter.defaultCenter().postNotificationName(kErrorNotification, object: nil, userInfo: userInfoDict)
        }
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let wrappedError: NSError = error {
            let userInfoDict:[String: AnyObject] = [kUnderlyingErrorsArrayKey: [wrappedError]]
            NSNotificationCenter.defaultCenter().postNotificationName(kErrorNotification, object: nil, userInfo: userInfoDict)
        }
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, willPerformHTTPRedirection response: NSHTTPURLResponse, newRequest request: NSURLRequest, completionHandler: (NSURLRequest?) -> Void) {
        completionHandler(request)
    }

    // MARK: NSURLSessionDataTaskDelegate

    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        completionHandler(.BecomeDownload)
    }

    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didBecomeDownloadTask downloadTask: NSURLSessionDownloadTask) {

    }

    // TODO: Change the key management strategy so that regular NSFetchRequests can be used
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, willCacheResponse proposedResponse: NSCachedURLResponse, completionHandler: (NSCachedURLResponse?) -> Void) {
        // TODO: Change to non optionals
        //        let operation = DataConditionerOperation(parentContext: self.coordinator.primaryBackgroundContext!, requestResponse: nil, data: proposedResponse.data)
        //        self.DataConditionerOperationQueue .addOperation(operation)
        //        completionHandler(self.coordinator.CoordinatorCachingPolicyEnabled ? proposedResponse : nil)
    }

    // Convert all of the operation processor (including default) to be registered with the system.
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {

        if let response = downloadTask.response as? NSHTTPURLResponse, let URLRequest = downloadTask.originalRequest, let context = self.coordinator.dataManager?.networkContext where response.statusCode == 200 {

            if let responseOperation = URLRequest.responseOperation as? String, let stackID = self.coordinator.dataManager?.stackID, let operationProcessor = URLResponseFactory.processor(responseOperation, stackID: stackID) {
                let operation = operationProcessor.process(session, downloadTask: downloadTask, didFinishDownloadingToURL: location, backgroundContext: context)
                let lock = NSLock()
                lock.lock()
                self.dataProcessingQueue.addOperation(operation)
                lock.unlock()

            } else {
                guard let sessionData = NSData(contentsOfURL: location)
                     else {
                        NSNotificationCenter.defaultCenter().postNotificationName(kErrorNotification, object: downloadTask.response, userInfo: nil)
                        return
                }
                let operation = DataConditionerOperation(parentContext: context, data: sessionData, URLRequest: URLRequest, graphManager: self)
                // TODO: Only the big requests cancel any pending operations.
//                if self.DataProcessingQueue.operationCount > 0 {
//                    self.DataProcessingQueue.cancelAllOperations()
//                }
                let lock = NSLock()
                lock.lock()
                self.dataProcessingQueue.addOperation(operation)
                lock.unlock()
            }

        } else {
            NSNotificationCenter.defaultCenter().postNotificationName(kErrorNotification, object: downloadTask.response, userInfo: nil)
        }
        
        
    }
}

