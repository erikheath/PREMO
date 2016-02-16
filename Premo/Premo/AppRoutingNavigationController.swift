//
//  AppRoutingNavigationController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/9/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit
import CoreData

class AppRoutingNavigationController: UINavigationController, SWRevealViewControllerDelegate {

    enum NavigationStack: String {
        case videoStack = "videoStack"
        case credentialStack = "credentialStack"
        case accountStack = "accountStack"
//        case loadingStack = "loadingStack"
    }

    // MARK: - Errors
    enum AppRoutingError: Int, ErrorType {
        case missingManagedObject = 5000

        var objectType : NSError {
            get {
                return NSError(domain: "LoginError", code: self.rawValue, userInfo: nil)
            }
        }
    }

    private var preloadContext = 0

    private var observerToken = false
    private var dispatchToken: dispatch_once_t = 0

    var foregroundView: UIView? = nil

    var currentNavigationStack: NavigationStack = NavigationStack.credentialStack

    var currentCategoryName: String? = nil

    var userWelcomed = false

    dynamic var reachable:NSNumber? = nil
    private var reachableToken = false

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        guard let dataLayer = (UIApplication.sharedApplication().delegate as! AppDelegate).datalayer where observerToken == true else { return }
        dataLayer.removeObserver(self, forKeyPath: "preloadComplete", context: &preloadContext)
        self.removeObserver(self, forKeyPath: "reachable", context: &reachableToken)

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let revealController = self.revealViewController() {
            revealController.delegate = self
        }

        self.transitionToInitialStack()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if self.viewControllers.last is VideoPlaybackViewController {
            return UIInterfaceOrientationMask.Landscape
        } else {
            return UIInterfaceOrientationMask.Portrait
        }
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }

    // MARK: - Navigation

    func transitionToInitialStack() -> Void {

        guard let dataLayer = (UIApplication.sharedApplication().delegate as! AppDelegate).datalayer else { return }
        objc_sync_enter(dataLayer)
        if dataLayer.preloadComplete == false {
            self.transitionToLoadingScreen(false)
            dispatch_once(&dispatchToken) { () -> Void in
                self.observerToken = true
                self.addObserver(self, forKeyPath: "reachable", options: .New, context: &self.reachableToken)
                dataLayer.addObserver(self, forKeyPath: "preloadComplete", options: NSKeyValueObservingOptions.init(rawValue:(NSKeyValueObservingOptions.Initial.rawValue | NSKeyValueObservingOptions.New.rawValue)), context: &self.preloadContext)
            }

        }
        objc_sync_exit(dataLayer)

        guard observerToken == false else { return }

        switch self.currentNavigationStack {

        case .videoStack:
            self.transitionToVideoStack(true)

        case .credentialStack:
            if Account.loggedIn == true {
                // take the user to features
                self.transitionToVideoStack(true)
            } else {
                // take the user to login.
                self.transitionToCredentialStack(true)
            }

        case .accountStack:
            self.transitionToAccountStack(true)

        }

    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &preloadContext {
            if let preloadSucceeded = change?[NSKeyValueChangeNewKey] as? NSNumber where preloadSucceeded.boolValue == true {

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
                    guard self.viewControllers.first is LaunchScreenViewController else { return }
                    switch self.currentNavigationStack {

                    case .videoStack:
                        self.transitionToVideoStack(true)

                    case .credentialStack:
                        if Account.loggedIn == true || self.userWelcomed == true {
                            // take the user to features
                            self.transitionToVideoStack(true)
                        } else {
                            // take the user to login.
                            self.transitionToCredentialStack(true)
                        }
                        
                    case .accountStack:
                        self.transitionToAccountStack(true)
                        
                    }
                })
                
            } else if let preloadSucceeded = change?[NSKeyValueChangeNewKey] as? NSNumber where preloadSucceeded.boolValue == false && Account.loggedIn == false && self.userWelcomed == false && AppDelegate.PREMOMainHostReachability?.currentReachabilityStatus() != NotReachable {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
                    guard self.viewControllers.first is LaunchScreenViewController else { return }
                    self.userWelcomed = true
                    self.transitionToCredentialStack(true)
                })
            } else if AppDelegate.PREMOMainHostReachability?.currentReachabilityStatus() == NotReachable {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged:", name: AppDelegate.ReachabilityStatus.Reachable.rawValue, object: nil)
            }
        }

        if context == &reachableToken {
            if let canReach = change?[NSKeyValueChangeNewKey] as? NSNumber where canReach.boolValue == true && Account.loggedIn == false && self.userWelcomed == false {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.25 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), { () -> Void in
                    guard self.viewControllers.first is LaunchScreenViewController else { return }
                    self.userWelcomed = true
                    self.transitionToCredentialStack(true)
                })
            }
        }
    }

    func reachabilityChanged(notification: NSNotification) {
        self.reachable = NSNumber(bool: true)
    }

    func transitionToLoadingScreen(animated: Bool) -> Void {
        guard let rootController = self.storyboard?.instantiateViewControllerWithIdentifier("loadingScreen") else { return }
        let controllers = [rootController]
        self.setViewControllers(controllers, animated: animated)

    }

    func transitionToAccountStack(animated: Bool) -> Void {
        // Set Account as root state.

        guard let rootController = self.storyboard?.instantiateViewControllerWithIdentifier("AccountTableViewController") as? AccountTableViewController else {
            // a fatal error has occurred.
            return
        }

        let controllers = [rootController]
        self.setViewControllers(controllers, animated: animated)
        self.currentNavigationStack = .accountStack

    }

    func transitionToVideoStack(animated: Bool) -> Void {

        guard let dataLayer = (UIApplication.sharedApplication().delegate as! AppDelegate).datalayer else { return }
        objc_sync_enter(dataLayer)
        if dataLayer.preloadComplete == false {
            self.transitionToLoadingScreen(true)
            objc_sync_exit(dataLayer)
            return
        }
        objc_sync_exit(dataLayer)

        // Set menu as root state. Load the view controllers from the storyboard into an array and reset.

        guard let rootController = self.storyboard?.instantiateViewControllerWithIdentifier("CategoryTableViewController") as? CategoryTableViewController else {
                // a fatal error has occurred.
                return
        }

        let controllers = [rootController]
        self.setViewControllers(controllers, animated: animated)

        // Configure once they are in the navigation stack

        guard let managedObjectContext = (UIApplication.sharedApplication().delegate as? AppDelegate)!.managedObjectContext else { return } // Add Error Handling
        rootController.managedObjectContext = managedObjectContext
        if self.currentCategoryName == nil {
            let fetchRequest = NSFetchRequest()
            let entity = NSEntityDescription.entityForName("CategoryList", inManagedObjectContext: managedObjectContext)
            fetchRequest.entity = entity

            // Set the batch size to a suitable number.
            fetchRequest.fetchBatchSize = 20

            // Edit the sort key as appropriate.
            let sortDescriptor = NSSortDescriptor(key: "remoteOrderPosition", ascending: true)
            fetchRequest.sortDescriptors = [sortDescriptor]

            do {
                let objects = try managedObjectContext.executeFetchRequest(fetchRequest)
                guard let managedObject = objects.first as? CategoryList else { throw AppRoutingError.missingManagedObject }
                self.currentCategoryName = managedObject.categoryName
            } catch {
                self.currentCategoryName = AppDelegate.defaultCategory
            }
        }
        rootController.categoryObjectName = self.currentCategoryName!
        self.currentNavigationStack = .videoStack

        (self.parentViewController as? UINavigationController)?.setNavigationBarHidden(false, animated: false)

    }

    func transitionToCredentialStack(animated: Bool) -> Void {
        // Set Welcome as root state.

        guard let rootController = self.storyboard?.instantiateViewControllerWithIdentifier("WelcomeViewController") as? WelcomeViewController else {
            // a fatal error has occurred.
            return
        }

        let controllers = [rootController]
        self.setViewControllers(controllers, animated: animated)
        self.currentNavigationStack = .credentialStack

    }

    // MARK: - SWREVEAL CONTROLLER DELEGATE

    func revealController(revealController: SWRevealViewController!, willMoveToPosition position: FrontViewPosition) {
        if position != FrontViewPosition.Left {
            let currentScreenshot = UIScreen.mainScreen().snapshotViewAfterScreenUpdates(true)

            let foregroundView = UIView(frame: CGRect(x: 0.0, y: 64.0, width: currentScreenshot.frame.size.width, height: currentScreenshot.frame.size.height))
            foregroundView.backgroundColor = UIColor.clearColor()
            revealController.frontViewController.view.addSubview(foregroundView)
            foregroundView.addGestureRecognizer(revealController.tapGestureRecognizer())
            self.foregroundView = foregroundView

            ((revealController.frontViewController as? AppRoutingNavigationController)?.topViewController as? CategoryTableViewController)?.pauseCarouselAnimation()
        }
    }

    func revealController(revealController: SWRevealViewController!, animateToPosition position: FrontViewPosition) {
        guard let currentScreenshot = self.foregroundView else { return }
        if position != FrontViewPosition.Left {
            currentScreenshot.backgroundColor = UIColor(colorLiteralRed: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        } else {
            currentScreenshot.backgroundColor = UIColor.clearColor()
        }
    }

    func revealController(revealController: SWRevealViewController!, didMoveToPosition position: FrontViewPosition) {
        if position == FrontViewPosition.Left {
            self.foregroundView?.removeFromSuperview()
            self.foregroundView = nil
            ((revealController.frontViewController as? AppRoutingNavigationController)?.topViewController as? CategoryTableViewController)?.animateCarousel(true)
        }
    }


}
