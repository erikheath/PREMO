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

    var backgroundView: UIView? = nil
    var foregroundView: UIView? = nil

    var currentNavigationStack: NavigationStack = NavigationStack.credentialStack

    var currentCategoryName: String? = nil

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

        switch self.currentNavigationStack {

        case .videoStack:
            self.transitionToVideoStack(false)

        case .credentialStack:
            if Account.loggedIn == true {
                // take the user to features
                self.transitionToVideoStack(false)
            } else {
                // take the user to login.
                self.transitionToCredentialStack(false)
            }

        case .accountStack:
            self.transitionToAccountStack(false)

        }
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
            revealController.frontViewController.view.addSubview(currentScreenshot)
            self.backgroundView = currentScreenshot

            let foregroundView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: currentScreenshot.frame.size.width, height: currentScreenshot.frame.size.height))
            foregroundView.backgroundColor = UIColor.clearColor()
            revealController.frontViewController.view.addSubview(foregroundView)
            foregroundView.addGestureRecognizer(revealController.tapGestureRecognizer())
            self.foregroundView = foregroundView
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
            self.backgroundView?.removeFromSuperview()
            self.foregroundView?.removeFromSuperview()
            self.backgroundView = nil
            self.foregroundView = nil
        }
    }


}
