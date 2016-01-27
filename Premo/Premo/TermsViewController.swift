//
//  TermsViewController.swift
//

import UIKit

class TermsViewController: UIViewController  {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.configureNavigationItemAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureNavigationItemAppearance()
    }


    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = "Privacy Policy & Terms"
            if let _ = self.navigationItem.title {
            self.navigationItem.titleView = PremoStyleTemplate.styledTitleLabel(self.navigationItem.title!)
            }
            self.navigationItem.hidesBackButton = false

        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = false
            PremoStyleTemplate.styleVisibleNavBar(navbarController.navigationBar)

        }
    }


    override func viewDidLoad() {
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        termsOfUseText.setContentOffset(CGPointZero, animated: false)
        privacyPolicyText.setContentOffset(CGPointZero, animated: false)
        (self.revealViewController() as? SlideController)!.blackStatusBarBackgroundView?.backgroundColor = UIColor.blackColor()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    @IBOutlet weak var termsOfUseButton: UIButton!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    @IBOutlet weak var termsOfUseText: UITextView!
    @IBOutlet weak var privacyPolicyText: UITextView!
    
    @IBAction func showTermsOfUse(sender: AnyObject) {
        termsOfUseButton.selected = true
        privacyPolicyButton.selected = false
        termsOfUseText.hidden = false
        privacyPolicyText.hidden = true
    }

    @IBAction func showPrivacyPolicy(sender: AnyObject) {
        termsOfUseButton.selected = false
        privacyPolicyButton.selected = true
        termsOfUseText.hidden = true
        privacyPolicyText.hidden = false
    }

}
