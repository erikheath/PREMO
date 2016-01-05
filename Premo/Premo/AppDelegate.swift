//
//  AppDelegate.swift
//

import UIKit
import CoreData

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

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

    lazy var datalayer: DataLayer? = {

        do {
            let storeURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent("PREMOCatalog.sqlite")
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

        if self.datalayer == nil {
            // This causes the catalog to be loaded.
            return false
        }

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

