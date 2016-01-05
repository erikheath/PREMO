//
//  AccountTableViewController.swift
//

import UIKit
import MessageUI

class AccountTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        guard let navbarController = self.parentViewController as? UINavigationController else { return }
        navbarController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "menu_fff")
        navbarController.navigationBar.backIndicatorImage = UIImage(named: "menu_fff")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
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

}
