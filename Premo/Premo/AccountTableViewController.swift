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

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        guard let navbarController = self.parentViewController as? UINavigationController else { return }
        navbarController.navigationBar.backIndicatorTransitionMaskImage = nil
        navbarController.navigationBar.backIndicatorImage = nil
        navbarController.navigationBarHidden = false

        self.updateLoginCellDisplay()
        self.updateSubscribeCellDisplay()
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
        guard let subscriptionExpiresDate = NSUserDefaults.standardUserDefaults().objectForKey("subscriptionExpiresDate") as? NSDate else {
            // The user has never had a subscription, so display the teaser.
            self.subscribeCallToActionLabel.text = "SUBSCRIBE NOW"
            self.subscribeTeaserLabel.text = "$4.99 / month, Free 30-day trial"
            return
        }
        let subscriptionActive = subscriptionExpiresDate.compare(NSDate()) == NSComparisonResult.OrderedDescending
        let subscriptionRenews = NSUserDefaults.standardUserDefaults().boolForKey("subscriptionAutoRenew")
        guard let subscriptionSource = NSUserDefaults.standardUserDefaults().stringForKey("subscriptionSource") else {
            // Create an error to let the user know there was a problem with their subscription.
            return
        }

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

    @IBAction func unwindFromSubscribe(unwindSegue: UIStoryboardSegue) {

    }

    // MARK: - Table

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 2:
            guard let tag = tableView.cellForRowAtIndexPath(indexPath)?.tag else { break } // Maybe show an error ?
            switch tag {
            case 0, 1, 4:
                // iTunes
                break
            default:
                // www.premonetwork.com
                guard let accountURL = NSURL(string: "http://www.premonetwork.com") else {
                    // throw some sort of error?
                    return
                }
                UIApplication.sharedApplication().openURL(accountURL)
                break
            }
        case 6:
            guard let supportSite = NSURL(string: "http://www.premonetwork.com/support") else { return }
            UIApplication.sharedApplication().openURL(supportSite)
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

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch identifier {
        case "showLoginFromAccount":
            // is the user already logged in?
            guard let _ = NSUserDefaults.standardUserDefaults().stringForKey("jwt") else {
                break
            }
            // log the user out?
            let alert = UIAlertController(title: "Log Out of Account?", message: "This will decrease the number of playback items associated with your account.", preferredStyle: UIAlertControllerStyle.Alert)
            let alertDefaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                // remove the users credentials and update the table.
                NSUserDefaults.standardUserDefaults().removeObjectForKey("jwt")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("userName")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("firstName")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("lastName")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("subscription")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("subscriptionSource")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("subscriptionCreatedDate")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("subscriptionExpiresDate")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("subscriptionValidUntilDate")
                NSUserDefaults.standardUserDefaults().removeObjectForKey("subscriptionAutoRenew")

                self.updateLoginCellDisplay()
                self.updateSubscribeCellDisplay()

            })
            let alertCancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            alert.addAction(alertDefaultAction)
            alert.addAction(alertCancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
            return false
        default:
            break
        }
        return true
    }
    
}
