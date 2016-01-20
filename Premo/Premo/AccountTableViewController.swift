//
//  AccountTableViewController.swift
//

import UIKit
import MessageUI

class AccountTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var loginStateLabel: UILabel!

    @IBOutlet weak var loginNameLabel: UILabel!

    @IBOutlet weak var subscribeCallToActionLabel: UILabel!

    @IBOutlet weak var subscribeTeaserLabel: UILabel!

    @IBOutlet weak var subscribeCell: UITableViewCell!


    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.configureNavigationItemAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureNavigationItemAppearance()
    }

    override init(style: UITableViewStyle) {
        super.init(style: style)
        self.configureNavigationItemAppearance()
    }

    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = "Account"
            self.navigationItem.hidesBackButton = true

        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = false
        }

        revealControllerSetup: do {
            guard let revealController = self.revealViewController() else {
                break revealControllerSetup
            }
            let toggleButton = UIBarButtonItem(title: "toggle", style: .Plain, target: revealController, action: "revealToggle:")
            toggleButton.image = UIImage(named: "menu_fff")
            self.navigationItem.leftBarButtonItem = toggleButton
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        self.updateLoginCellDisplay()
        self.updateSubscribeCellDisplay()
    }

    override func viewWillAppear(animated: Bool) {
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        self.updateLoginCellDisplay()
        self.updateSubscribeCellDisplay()
        super.viewWillAppear(animated)
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }


    func updateLoginCellDisplay() {
        guard let _ = NSUserDefaults.standardUserDefaults().stringForKey("jwt"), let userName = NSUserDefaults.standardUserDefaults().stringForKey("userName") else {
            // The user is not logged in.
            self.loginStateLabel.text = "LOG IN"
            self.loginNameLabel.text = "Log in or sign up"
            return
        }

        // The user is logged in.
        self.loginStateLabel.text = "LOG OUT"
        self.loginNameLabel.text = userName
    }

    func updateSubscribeCellDisplay() {
        guard let subscriptionExpiresDate = Account.expirationDate, let subscriptionRenews = Account.autoRenews, let subscriptionSource = Account.source else {
            // The user has never had a subscription, so display the teaser.
            self.subscribeCallToActionLabel.text = "SUBSCRIBE NOW"
            self.subscribeTeaserLabel.text = "$4.99 / month, Free 30-day trial"
            return
        }
        let subscriptionActive = subscriptionExpiresDate.compare(NSDate()) == NSComparisonResult.OrderedDescending

        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"

        if subscriptionActive == true {
            switch subscriptionSource {
            case "itunes":
                if subscriptionRenews == true {
                    self.subscribeCallToActionLabel.text = "SUBSCRIPTION RENEWS ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                    self.subscribeTeaserLabel.text = "Manage your subscription"
                    self.subscribeCell.tag = 0

                } else {
                    self.subscribeCallToActionLabel.text = "SUBSCRIPTION EXPIRES ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                    self.subscribeTeaserLabel.text = "Renew now"
                    self.subscribeCell.tag = 1
                }
            default:
                if subscriptionRenews == true {
                    self.subscribeCallToActionLabel.text = "SUBSCRIPTION RENEWS ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                    self.subscribeTeaserLabel.text = "Manage your account at www.premonetwork.com"
                    self.subscribeCell.tag = 2
                } else {
                    self.subscribeCallToActionLabel.text = "SUBSCRIPTION EXPIRES ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                    self.subscribeTeaserLabel.text = "Update your account at www.premonetwork.com"
                    self.subscribeCell.tag = 3
                }
            }
        } else {
            switch subscriptionSource {
            case "itunes":

                self.subscribeCallToActionLabel.text = "SUBSCRIPTION EXPIRED ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                self.subscribeTeaserLabel.text = "Renew now"
                self.subscribeCell.tag = 4

            default:

                self.subscribeCallToActionLabel.text = "SUBSCRIPTION EXPIRED ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                self.subscribeTeaserLabel.text = "Update your account at www.premonetwork.com"
                self.subscribeCell.tag = 5
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Navigation

    @IBAction func loginOrOut(sender: AnyObject) {
        // is the user already logged in?
        if Account.loggedIn == true {
            confirmLogout()
        } else {
            self.presentLoginFlow()
        }
    }

    func presentLoginFlow() {
        self.performSegueWithIdentifier("showLogin", sender: self)
    }

    func confirmLogout() {
        let alert = UIAlertController(title: "Log Out of Account?", message: "This will decrease the number of playback items associated with your account.", preferredStyle: UIAlertControllerStyle.Alert)
        let alertDefaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
            // remove the users credentials and update the table.
            Account.removeDeviceFromService()
            Account.clearAccountSettings()
            self.updateLoginCellDisplay()

        })
        let alertCancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        alert.addAction(alertDefaultAction)
        alert.addAction(alertCancelAction)

        self.presentViewController(alert, animated: true, completion: nil)

    }

    @IBAction func subscribeOrManage(sender: AnyObject) {
        if Account.loggedIn == false {
            self.performSegueWithIdentifier("showLogin", sender: self)
        } else if Account.source == nil {
            self.performSegueWithIdentifier("showSubscribe", sender: self)
        } else if Account.source == "itunes" {
            UIApplication.sharedApplication().openURL(Account.iTunesSubscriptionManagement!)
        } else {
            UIApplication.sharedApplication().openURL(Account.premoAccoutManagementSite!)
        }
    }


    @IBAction func unwindFromSubscribe(unwindSegue: UIStoryboardSegue) {

    }


    // MARK: - Table

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 6:
            UIApplication.sharedApplication().openURL(Account.supportSite!)
        case 8:
            guard MFMailComposeViewController.canSendMail() == true else { return }
            let sendFeedbackMailView = MFMailComposeViewController()
            sendFeedbackMailView.mailComposeDelegate = self
            sendFeedbackMailView.setSubject("Feedback")
            sendFeedbackMailView.setToRecipients(["support@premonetwork.com"])
            sendFeedbackMailView.setMessageBody("Please enter your feedback here.", isHTML: false)
            sendFeedbackMailView.modalPresentationStyle = UIModalPresentationStyle.FullScreen
            sendFeedbackMailView.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
            self.presentViewController(sendFeedbackMailView, animated: true, completion: nil)
        default:
            break
        }
    }

    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result {
        case MFMailComposeResultCancelled:
            break
        case MFMailComposeResultFailed:
            break
        case MFMailComposeResultSaved:
            break
        case MFMailComposeResultSent:
            break
        default:
            break
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }


}
