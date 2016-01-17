//
//  WelcomeViewController.swift
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!

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

    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }


    @IBAction func skipLogin(sender: AnyObject) {
        if (self.navigationController as? AppRoutingNavigationController)!.currentNavigationStack == .credentialStack {
            (self.navigationController as? AppRoutingNavigationController)!.transitionToVideoStack(true)
        } else {
            self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
        }
    }

}
