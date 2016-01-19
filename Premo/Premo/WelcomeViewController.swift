//
//  WelcomeViewController.swift
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!


    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.configureNavigationItemAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureNavigationItemAppearance()
    }

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

        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()

    }

    override func viewWillAppear(animated: Bool) {
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        super.viewWillAppear(animated)
    }

    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = ""
            self.navigationItem.hidesBackButton = true
        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = true
        }
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
