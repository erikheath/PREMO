//
//  AppDelegate.swift
//

import UIKit
import CoreData
import StoreKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, SKPaymentTransactionObserver, NSURLSessionDelegate, NSURLSessionDataDelegate {

    var window: UIWindow?

    var appDeviceID: String = {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let premoID = defaults.stringForKey("PREMOID") {
            return premoID
        } else {
            let premoID = NSUUID().UUIDString
            defaults.setObject(premoID, forKey: "PREMOID")
            return premoID
        }
    }()

    enum subscription: String {
        case JSONWebToken = "jwt"
        case userName = "username"
        case firstName = "firstName"
        case lastName = "lastName"
        case subscriptionCreatedDate = "subscriptionCreatedDate"
        case subscriptionExpiresDate = "subscriptionExpiresDate"
        case subscriptionValidUntilDate = "subscriptionValidUntilDate"
        case subscriptionAutoRenew = "subscriptionAutoRenew"
    }

    var loggedIn: Bool {
        if NSUserDefaults.standardUserDefaults().stringForKey(subscription.JSONWebToken.rawValue) != nil {
            return true
        }
        return false

    }

    enum TransactionStatusNotification: String {
        case purchasing = "PurchaseProcessingNotification"
        case purchased = "PurchaseCompleteNotification"
        case deferred = "PurchaseDeferredNotification"
        case failed = "PurchaseFailedNotification"
        case restored = "PurchaseRestoredNotification"
    }

    lazy var transactionSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)

    lazy var datalayer: DataLayer? = {

        do {
            let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PREMOCatalog.sqlite")
            print(storeURL)
            let store = StoreReference(storeType: NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            guard let modelURL = NSBundle.mainBundle().URLForResource("Premo", withExtension: "momd") else { throw DataLayerError.genericError }
            guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else { throw DataLayerError.genericError }
            let preloadRequest = NetworkStoreFetchRequest(entityName: "AppConfig")

            let layer = try DataLayer(stores: [store], model: model, preload: preloadRequest)

            return layer
        } catch {
            print(error)
            return nil
        }
    }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // UI Customization
        let navbarProxy = UINavigationBar.appearance()
        navbarProxy.barTintColor = UIColor.blackColor()
        navbarProxy.tintColor = UIColor.whiteColor()
        navbarProxy.barStyle = UIBarStyle.Black
        navbarProxy.titleTextAttributes = [NSFontAttributeName: self.navBarFont()]

        // Set up Data Layer
        JSONObjectDataConditionerFactory.registerObjectConditioner(ContentItemJSONObjectConditioner.entityName, objectConditioner: ContentItemJSONObjectConditioner())
        if self.datalayer == nil {
            // This causes the catalog to be loaded. Also, the app can't run without this.
            return false
        }

        SKPaymentQueue.defaultQueue().addTransactionObserver(self)


        return true
    }

    func navBarFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Light", size: 17)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 17)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        //        do {
        //            try self.saveContext()
        //        } catch {
        //
        //        }
    }

    // MARK: - Purchase Management

    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {

            case SKPaymentTransactionState.Purchasing:
                let notification = NSNotification(name: TransactionStatusNotification.purchasing.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case SKPaymentTransactionState.Deferred:
                let notification = NSNotification(name: TransactionStatusNotification.deferred.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case SKPaymentTransactionState.Failed:
                let notification = NSNotification(name: TransactionStatusNotification.failed.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            case SKPaymentTransactionState.Purchased:
                let notification = NSNotification(name: TransactionStatusNotification.purchased.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)
                self.processPurchasedTransaction(transaction)

            case SKPaymentTransactionState.Restored:
                let notification = NSNotification(name: TransactionStatusNotification.restored.rawValue, object: transaction, userInfo: nil)
                NSNotificationCenter.defaultCenter().postNotification(notification)

            }
        }
    }

    func processPurchasedTransaction(transaction: SKPaymentTransaction) {
        do {
            guard let subscriptionURL = NSURL(string: "http://lava-dev.premonetwork.com:3000/api/v1/subscription/create") else { return } // There needs to be error handling
            let subscriptionRequest = NSMutableURLRequest(URL: subscriptionURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 45.0)
            subscriptionRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
            subscriptionRequest.setValue(NSUserDefaults.standardUserDefaults().stringForKey("jwt"), forHTTPHeaderField: "Authorization")
            guard let receiptURL = NSBundle.mainBundle().appStoreReceiptURL, let receiptData = NSData(contentsOfURL: receiptURL) else { return } // throw an error
            subscriptionRequest.HTTPBody = try NSJSONSerialization.dataWithJSONObject(["recurlyToken":receiptData], options: NSJSONWritingOptions.init(rawValue: 0))
            let subscriptionRequestTask = self.transactionSession.dataTaskWithRequest(subscriptionRequest, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                do {
                    if error != nil || data == nil { return } // There should be some error handling.
                    // TODO: Ensure that all of the subscription stuff is here.
                    guard let JSONObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary, let success = JSONObject.objectForKey("success") where (success as? NSNumber)!.boolValue == true, let subscription = (JSONObject.objectForKey("payload") as? NSDictionary)!.objectForKey("subscription") as? NSDictionary, let subscriptionCreatedString = subscription.objectForKey("created") as? String, let subscriptionExpiresString = subscription.objectForKey("expires") as? String, let subscriptionValidUntilString = subscription.objectForKey("validUntil") as? String, let autoRenewBool = subscription.objectForKey("autoRenew") as? NSNumber, let subscriptionSourceString = subscription.objectForKey("source") else { return } // Error handling
                    NSUserDefaults.standardUserDefaults().setObject(subscriptionSourceString, forKey: "subscriptionSource")

                    let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.locale = enUSPOSIXLocale
                    dateFormatter.dateFormat = "yyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
                    dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
                    if let subscriptionCreatedDate = dateFormatter.dateFromString(subscriptionCreatedString), let subscriptionExpiresDate = dateFormatter.dateFromString(subscriptionExpiresString), let subscriptionValidUntilDate = dateFormatter.dateFromString(subscriptionValidUntilString) {
                        NSUserDefaults.standardUserDefaults().setObject(subscriptionCreatedDate, forKey: "subscriptionCreatedDate")
                        NSUserDefaults.standardUserDefaults().setObject(subscriptionExpiresDate, forKey: "subscriptionExpiresDate")
                        NSUserDefaults.standardUserDefaults().setObject(subscriptionValidUntilDate, forKey: "subscriptionValidUntilDate")
                        NSUserDefaults.standardUserDefaults().setBool(autoRenewBool.boolValue, forKey: "subscriptionAutoRenew")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    }


                } catch {  }
            })

            subscriptionRequestTask.resume()

        } catch {}

    }

    // MARK: - Core Data stack

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Premo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.movesalesinc.FoundationsSwiftTestApp" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        return self.datalayer?.mainContext
    }()
    
}

