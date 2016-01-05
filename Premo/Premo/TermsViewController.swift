//
//  TermsViewController.swift
//

import UIKit

class TermsViewController: UIViewController  {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        guard let navbarController = self.parentViewController as? UINavigationController else { return }
        navbarController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "back")
        navbarController.navigationBar.backIndicatorImage = UIImage(named: "back")
        self.navigationItem.title = "Privacy Policy & Terms"


    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        termsOfUseText.setContentOffset(CGPointZero, animated: false)
        privacyPolicyText.setContentOffset(CGPointZero, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
