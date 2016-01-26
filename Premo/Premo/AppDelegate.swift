//
//  AppDelegate.swift
//

import UIKit
import CoreData
import StoreKit
import FBSDKCoreKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {

    /**
     Application Window reference
     */
    var window: UIWindow?

    /**
     The default category that should be used when nothing is available.
     */
    static let defaultCategory = "Featured"

    /**
    Provides a semi-static reference to the device. Used for limiting the number of devices that a user can use at the same time.
     */
    static var appDeviceID: String = {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let premoID = defaults.stringForKey("PREMOID") {
            return premoID
        } else {
            let premoID = NSUUID().UUIDString
            defaults.setObject(premoID, forKey: "PREMOID")
            return premoID
        }
    }()

    /**
     The base URL used for all requests to the premo servers.
     */
    static var PREMOURL: NSURL? = {
        let components = NSURLComponents()
        components.scheme = "http"
        components.host = "lava-dev.premonetwork.com"
        components.port = 3000
        return components.URL
    }()

    static var PREMOMainURL: NSURL? = {
        let components = NSURLComponents()
        components.scheme = "http"
        components.host = "www.premonetwork.com"
        return components.URL
    }()

    /**
     The data layer contains the currently available content. The data layer is refreshed:
     - on application launch
     - at a configured interval set in the app configuration file (see the app configuration object in the Managed Object Model).
     
     The data layer is kept in memory, but may be configured to write to disk if needed. See commented "let store = ..." line in the datalayer property for a pre-configured on-disk example.
     
     - Warning: If the data layer can't be constructed, the application can not run. As such, the application must terminate. Because property initializers can not throw error messages, the current reporting strategy is to print to standard out. Notifiying the user of the error / program state is the responsibility of the calling method / object.
     */
    lazy var datalayer: DataLayer? = {

        do {
//            let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PREMOCatalog.sqlite")
//            print(storeURL)
            let store = StoreReference(storeType: NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
//          let store = StoreReference(storeType: NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
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

    /**
     The transaction processor provides a unified object for handling user initiated store kit transactions as well as store kit driven transactions (e.g. auto-renew subscriptions). It must be instantiated no later than application:didFinishLaunchingWithOptions, but can also be part of the app delegate construction cycle.
     */
    let transactionProcessor: TransactionProcessor = TransactionProcessor()

    /**
     The registration processor provides a unified object for handling user initiated registration as well as store kit initiated registration (e.g. auto-renew subscriptions). It must be instantiated no later than application:didFinishLaunchingWithOptions, but can also be part of the app delegate construction cycle.
     */
    let registrationProcessor: RegistrationProcessor = RegistrationProcessor()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        // UI Customization
        PremoStyleTemplate.styleApp()

        // Set up Data Layer
        JSONObjectDataConditionerFactory.registerObjectConditioner(ContentItemJSONObjectConditioner.entityName, objectConditioner: ContentItemJSONObjectConditioner())
        if self.datalayer == nil {
            return false
            /*
            TODO: Notify user of Failure
            This causes the catalog to be loaded. Also, the app can't run without this. This would be an appropriate time to notify the user of the error.
            */

        }

        // Set up Facebook SDK
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        // Refresh the user's account if they are marked as logged in.
        do {
            if Account.loggedIn == true { try Account.refreshAccount() }
        } catch { return true }

        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {

        // Enable Facebook SDK to open the facebook app or web site.
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)

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



    // MARK: - Core Data stack

    /**
    The managed object model for the application.
    
    - Warning: It is a fatal error for the application not to be able to find and load its model.
    */
    lazy var managedObjectModel: NSManagedObjectModel = {
        //
        let modelURL = NSBundle.mainBundle().URLForResource("Premo", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    /**
     The directory the application uses to store the Core Data store file. This code uses a directory named "com.movesalesinc.FoundationsSwiftTestApp" in the application's documents Application Support directory.
     */
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    /**
     The main thread managed object context. For access to other contexts, query the app delegate's datalayer property.
     */
    lazy var managedObjectContext: NSManagedObjectContext? = {
        return self.datalayer?.mainContext
    }()
    
}

