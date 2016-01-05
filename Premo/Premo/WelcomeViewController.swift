//
//  WelcomeViewController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/1/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!

    var transitionCompletionHandler: (() -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        var buttonLayer = loginButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0
        buttonLayer.borderColor = UIColor.whiteColor().CGColor
        buttonLayer.borderWidth = 1.5

        buttonLayer = signupButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        (self.parentViewController as? UINavigationController)?.setNavigationBarHidden(true, animated: true)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

        if transitionCompletionHandler != nil {
            transitionCompletionHandler!()
            transitionCompletionHandler = nil
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Navigation

    func prepareTransitionCompletionHandler() -> (() -> Void) {
        return {
            // Replace to menu as root state. Load the view controllers from the storyboard into an array and reset.

            guard let rootController = self.storyboard?.instantiateViewControllerWithIdentifier("MenuTableViewController") as? MenuTableViewController,
                let featureController = self.storyboard?.instantiateViewControllerWithIdentifier("CategoryTableViewController") as? CategoryTableViewController,
                var controllers = self.navigationController?.viewControllers else {
                    // a fatal error has occurred.
                    return
            }

            controllers = [rootController, featureController]
            self.navigationController?.setViewControllers(controllers, animated: true)

            // Configure once they are in the navigation stack
            rootController.configureNavigation()
            let fetchController = rootController.fetchedResultsController

            guard let object = fetchController.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? CategoryList else {
                return
            }
            featureController.managedObjectContext = rootController.managedObjectContext
            featureController.categoryObject = object
            (self.parentViewController as? UINavigationController)?.setNavigationBarHidden(false, animated: false)

            self.navigationController?.popViewControllerAnimated(true)
            
        }
    }

    @IBAction func unwindFromSubscribe(sender: UIStoryboardSegue) {
        // Show a slight delay, fuzz of screen, then go to Featured.
        self.transitionCompletionHandler = self.prepareTransitionCompletionHandler()

    }

    @IBAction func skipLogin(sender: AnyObject) {
        self.transitionCompletionHandler = self.prepareTransitionCompletionHandler()
        self.transitionCompletionHandler!()
    }


}
