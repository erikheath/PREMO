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

    private var loadingError: Bool = false

    /**
     The base URL used for all requests to the premo servers.
     */
    static var PREMOURL: NSURL? = {
        let components = NSURLComponents()
        components.scheme = "https"
        components.host = "lava.premonetwork.com"
        return components.URL
    }()

    static var PREMOMainURL: NSURL? = {
        let components = NSURLComponents()
        components.scheme = "http"
        components.host = "www.premonetwork.com"
        return components.URL
    }()

    private(set) static var PREMOMainHostReachability: Reachability? = nil
    private var reachabilityTimer: NSTimer? = nil

    enum ReachabilityStatus: String {
        case NotReachable = "Not Reachable"
        case Reachable = "Reachable"
    }

    /**
     The data layer contains the currently available content. The data layer is refreshed:
     - on application launch
     - at a configured interval set in the app configuration file (see the app configuration object in the Managed Object Model).
     
     The data layer is kept in memory, but may be configured to write to disk if needed. See commented "let store = ..." line in the datalayer property for a pre-configured on-disk example.
     
     - Warning: If the data layer can't be constructed, the application can not run. As such, the application must terminate. Because property initializers can not throw error messages, the current reporting strategy is to print to standard out. Notifiying the user of the error / program state is the responsibility of the calling method / object.
     */
    lazy var datalayer: DataLayer? = {
        return self.reloadDataLayer()
    }()

    private func reloadDataLayer() -> DataLayer? {
        do {
            //            let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PREMOCatalog.sqlite")
            //            print(storeURL)
            let store = StoreReference(storeType: NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
            //          let store = StoreReference(storeType: NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            guard let modelURL = NSBundle.mainBundle().URLForResource("Premo", withExtension: "momd") else { throw DataLayerError.genericError }
            guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else { throw DataLayerError.genericError }
            let preloadRequest = NetworkStoreFetchRequest(entityName: "AppConfig")

            let layer = try DataLayer(stores: [store], model: model, preload: [preloadRequest], stackID: nil)

            return layer
        } catch {
            print(error)
            return nil
        }
    }

    /**
     The transaction processor provides a unified object for handling user initiated store kit transactions as well as store kit driven transactions (e.g. auto-renew subscriptions). It must be instantiated no later than application:didFinishLaunchingWithOptions, but can also be part of the app delegate construction cycle.
     */
    let transactionProcessor: TransactionProcessor = TransactionProcessor()

    /**
     The registration processor provides a unified object for handling user initiated registration as well as store kit initiated registration (e.g. auto-renew subscriptions). It must be instantiated no later than application:didFinishLaunchingWithOptions, but can also be part of the app delegate construction cycle.
     */
    let registrationProcessor: RegistrationProcessor = RegistrationProcessor()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        if self.datalayer == nil {
            return false
            /*
            TODO: Notify user of Failure
            This causes the catalog to be loaded. Also, the app can't run without this. This would be an appropriate time to notify the user of the error.
            */

        }
        // Observe data layer preload status
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "preloadCompleted:", name: "preloadComplete", object: nil)

        // Set up Reachability Monitors
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: kReachabilityChangedNotification, object: nil)

        AppDelegate.PREMOMainHostReachability = Reachability(hostName: "www.premonetwork.com")
        AppDelegate.PREMOMainHostReachability?.startNotifier()

        // UI Customization
        PremoStyleTemplate.styleApp()

        // Set up Data Layer
        JSONObjectDataConditionerFactory.registerObjectConditioner(ContentItemJSONObjectConditioner.entityName, objectConditioner: ContentItemJSONObjectConditioner())

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

    // MARK: - Reachability stack

    func reachabilityChanged(notification: NSNotification) -> Void {
        guard let networkChecker = notification.object as? Reachability where networkChecker == AppDelegate.PREMOMainHostReachability else { return }

        self.pollConnectionStatusForChange(7.0, status: networkChecker.currentReachabilityStatus() == NotReachable ? .NotReachable : .Reachable)
    }

    func pollConnectionStatusForChange(interval: NSTimeInterval, status: ReachabilityStatus) -> Void {
        if self.reachabilityTimer != nil { return }
        self.reachabilityTimer = NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: "postConnectionStatus:", userInfo: ["status": status.rawValue], repeats: false)
    }

    func postConnectionStatus(reconnectTimer: NSTimer) -> Void {
        self.reachabilityTimer = nil
        defer {
            reconnectTimer.invalidate()
        }
        guard let priorStatus = reconnectTimer.userInfo?["status"] as? String else { return }
        let currentStatus = AppDelegate.PREMOMainHostReachability?.currentReachabilityStatus() == NotReachable ? ReachabilityStatus.NotReachable.rawValue : ReachabilityStatus.Reachable.rawValue
        if currentStatus == priorStatus {
            NSNotificationCenter.defaultCenter().postNotificationName(currentStatus, object: nil)
            if currentStatus == ReachabilityStatus.Reachable.rawValue && self.datalayer?.preloadComplete == false {
                // Reload the DataLayer as it is in an unknown state.
                self.datalayer?.reset(true)
            }
        } else {
            self.pollConnectionStatusForChange(5.0, status: AppDelegate.ReachabilityStatus.init(rawValue: currentStatus)!)
        }
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

    /**
    Turn on auto refresh for the data layer using the configurable number of seconds delivered from the server.
    */
    func preloadCompleted(notification: NSNotification) {
        self.datalayer?.masterContext.performBlock({ () -> Void in
            do {
            let delayFetch = NSFetchRequest(entityName: "AppConfig")
            guard let config = try self.datalayer?.masterContext.executeFetchRequest(delayFetch).first as? AppConfig, let delay = config.refreshSeconds?.intValue else { return }
                self.datalayer?.refreshSeconds = Int(delay)
                self.datalayer?.autoRefresh = true
            } catch {

            }

        })
    }

}

