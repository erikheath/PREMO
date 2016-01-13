//
//  AppRoutingNavigationController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/9/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit

class AppRoutingNavigationController: UINavigationController {

//    override init(rootViewController: UIViewController) {
//        super.init(rootViewController: rootViewController)
//        self.transitionToInitialStack()
//    }
//
//    override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
//        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
//        self.transitionToInitialStack()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        self.transitionToInitialStack()
//    }
//
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
//        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
//        self.transitionToInitialStack()
//

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
