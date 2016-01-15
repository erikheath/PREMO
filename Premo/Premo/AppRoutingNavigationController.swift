//
//  AppRoutingNavigationController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/9/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit

class AppRoutingNavigationController: UINavigationController {

    enum NavigationStack: String {
        case videoStack = "videoStack"
        case credentialStack = "credentialStack"
    }

    var currentNavigationStack: NavigationStack = NavigationStack.credentialStack

    override func viewDidLoad() {
        super.viewDidLoad()
        self.transitionToInitialStack()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if self.viewControllers.last is VideoPlaybackViewController {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.Portrait
        }
    }


    // MARK: - Navigation

    func transitionToInitialStack() -> Void {
        if (UIApplication.sharedApplication().delegate as? AppDelegate)!.loggedIn == true {
            // take the user to features
            self.transitionToVideoStack(false)
        } else {
            // take the user to login.
            self.transitionToCredentialStack()
        }
    }

    func transitionToVideoStack(animated: Bool) -> Void {
        // Set menu as root state. Load the view controllers from the storyboard into an array and reset.

        guard let categoryController = self.storyboard?.instantiateViewControllerWithIdentifier("CategoryTableViewController") as? CategoryTableViewController, let rootController = self.storyboard?.instantiateViewControllerWithIdentifier("MenuTableViewController") as? MenuTableViewController else {
                // a fatal error has occurred.
                return
        }

        let controllers = [rootController, categoryController]
        self.setViewControllers(controllers, animated: animated)

        // Configure once they are in the navigation stack
        rootController.configureNavigation()

        categoryController.managedObjectContext = rootController.managedObjectContext
        categoryController.categoryObjectName = "Featured"
        (self.parentViewController as? UINavigationController)?.setNavigationBarHidden(false, animated: false)
        self.currentNavigationStack = .videoStack

    }

    func transitionToCredentialStack() -> Void {
        // Set Welcome as root state.

        guard let rootController = self.storyboard?.instantiateViewControllerWithIdentifier("WelcomeViewController") as? WelcomeViewController else {
            // a fatal error has occurred.
            return
        }

        let controllers = [rootController]
        self.setViewControllers(controllers, animated: false)
        self.currentNavigationStack = .credentialStack

    }

}
