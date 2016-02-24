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

    @IBOutlet weak var help: UITableViewCell!

    @IBOutlet weak var sendFeedback: UITableViewCell!

    @IBOutlet weak var aboutPremo: UITableViewCell!

    @IBOutlet weak var privacyPolicy: UITableViewCell!

    @IBOutlet weak var premoForIOS: UILabel!

    @IBOutlet weak var versionLabel: UILabel!

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
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "  ", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = "Account"
            if let _ = self.navigationItem.title {
                self.navigationItem.titleView = PremoStyleTemplate.styledTitleLabel(self.navigationItem.title!)
            }
            self.navigationItem.hidesBackButton = true

        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = false
            PremoStyleTemplate.styleVisibleNavBar(navbarController.navigationBar)

        }

        revealControllerSetup: do {
            guard let revealController = self.revealViewController() else {
                break revealControllerSetup
            }
            let toggleButton = UIBarButtonItem(title: "    ", style: .Plain, target: revealController, action: "revealToggle:")
            toggleButton.image = UIImage(named: "menu_fff")
            self.navigationItem.leftBarButtonItem = toggleButton
        }
    }

    func accountHeaderFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 12.0)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 12.0)
    }

    func accountMainLabelFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 12.0)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 12.0)
    }

    func accountDetailLabelFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Light", size: 12.5)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 12.5)
    }


    func accountMainLabelAttributedString(header: String) -> NSAttributedString {
        let itemTitle = (header as NSString).uppercaseString
        let mutableItemTitle = NSMutableAttributedString(string: itemTitle)
        mutableItemTitle.addAttribute(NSFontAttributeName, value: self.accountMainLabelFont(), range: NSMakeRange(0, mutableItemTitle.length))
        mutableItemTitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableItemTitle.length))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.defaultParagraphStyle())
        paragraphStyle.firstLineHeadIndent = 4.5
        mutableItemTitle.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, mutableItemTitle.length))
        return mutableItemTitle
    }

    func accountHeaderAttributedString(header: String) -> NSAttributedString {
        let itemTitle = (header as NSString).uppercaseString
        let mutableItemTitle = NSMutableAttributedString(string: itemTitle)
        mutableItemTitle.addAttribute(NSFontAttributeName, value: self.accountHeaderFont(), range: NSMakeRange(0, mutableItemTitle.length))
        mutableItemTitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableItemTitle.length))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.defaultParagraphStyle())
        paragraphStyle.firstLineHeadIndent = 4.5
        mutableItemTitle.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, mutableItemTitle.length))
        return mutableItemTitle
    }



    func accountDetailLabelAttributedString(header: String) -> NSAttributedString {
        let itemTitle = header
        let mutableItemTitle = NSMutableAttributedString(string: itemTitle)
        mutableItemTitle.addAttribute(NSFontAttributeName, value: self.accountDetailLabelFont(), range: NSMakeRange(0, mutableItemTitle.length))
        mutableItemTitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableItemTitle.length))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.defaultParagraphStyle())
        paragraphStyle.firstLineHeadIndent = 4.5
        mutableItemTitle.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, mutableItemTitle.length))
        return mutableItemTitle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()

        self.updateLoginCellDisplay()
        self.updateSubscribeCellDisplay()

        self.help.textLabel?.attributedText = self.accountHeaderAttributedString((self.help.textLabel?.text)!)
        self.aboutPremo.textLabel?.attributedText = self.accountHeaderAttributedString((self.aboutPremo.textLabel?.text)!)
        self.sendFeedback.textLabel?.attributedText = self.accountHeaderAttributedString((self.sendFeedback.textLabel?.text)!)
        self.privacyPolicy.textLabel?.attributedText = self.accountHeaderAttributedString((self.privacyPolicy.textLabel?.text)!)
        self.premoForIOS?.attributedText = self.accountMainLabelAttributedString((self.premoForIOS?.text)!)
        self.versionLabel?.attributedText = self.accountDetailLabelAttributedString((self.versionLabel?.text)!)

    }

    override func viewWillAppear(animated: Bool) {
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        self.updateLoginCellDisplay()
        self.updateSubscribeCellDisplay()
        (self.revealViewController() as? SlideController)!.blackStatusBarBackgroundView?.backgroundColor = UIColor.blackColor()

        super.viewWillAppear(animated)
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }


    func updateLoginCellDisplay() {
        defer {
            self.loginStateLabel.attributedText = self.accountMainLabelAttributedString(self.loginStateLabel.text!)
            self.loginNameLabel.attributedText = self.accountDetailLabelAttributedString(self.loginNameLabel.text!)
        }

        do {
            guard let _ = Account.authorizationToken, let userName = Account.userName else {
                // The user is not logged in.
                self.loginStateLabel.text = "LOG IN"
                self.loginNameLabel.text = "Log in or sign up"
                return
            }

            // The user is logged in.
            self.loginStateLabel.text = "LOG OUT"
            self.loginNameLabel.text = userName
        }
    }

    func updateSubscribeCellDisplay() {

        defer {
            self.subscribeCallToActionLabel.attributedText = self.accountMainLabelAttributedString(self.subscribeCallToActionLabel.text!)
            self.subscribeTeaserLabel.attributedText = self.accountDetailLabelAttributedString(self.subscribeTeaserLabel.text!)
        }
        
        do {

            guard let subscriptionExpiresDate = Account.expirationDate, let subscriptionRenews = Account.autoRenews, let subscriptionSource = Account.source else {
                // The user has never had a subscription, so display the teaser.
                self.subscribeCallToActionLabel.text = "SUBSCRIBE NOW"
                self.subscribeTeaserLabel.text = "Only $4.99 / month, Free 30-day trial"
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
                        self.subscribeTeaserLabel.text = "Manage your subscription on iTunes"
                        self.subscribeCell.tag = 0

                    } else {
                        self.subscribeCallToActionLabel.text = "SUBSCRIPTION EXPIRES ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                        self.subscribeTeaserLabel.text = "Renew now on iTunes"
                        self.subscribeCell.tag = 1
                    }
                default:
                    if subscriptionRenews == true {
                        self.subscribeCallToActionLabel.text = "SUBSCRIPTION RENEWS ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                        self.subscribeTeaserLabel.text = "Manage your account at premonetwork.com"
                        self.subscribeCell.tag = 2
                    } else {
                        self.subscribeCallToActionLabel.text = "SUBSCRIPTION EXPIRES ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                        self.subscribeTeaserLabel.text = "Update your account at premonetwork.com"
                        self.subscribeCell.tag = 3
                    }
                }
            } else {
                switch subscriptionSource {
                default:

                    self.subscribeCallToActionLabel.text = "SUBSCRIPTION EXPIRED ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
                    self.subscribeTeaserLabel.text = "Renew now on iTunes"
                    self.subscribeCell.tag = 4

//                default:
//
//                    self.subscribeCallToActionLabel.text = "SUBSCRIPTION EXPIRED ON " + dateFormatter.stringFromDate(subscriptionExpiresDate)
//                    self.subscribeTeaserLabel.text = "Update your account at premonetwork.com"
//                    self.subscribeCell.tag = 5
                }
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
        let alert = UIAlertController(title: "Log Out of Account?", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        let alertDefaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
            // remove the users credentials and update the table.
            Account.removeDeviceFromService()
            Account.clearAccountSettings()
            self.updateLoginCellDisplay()
            self.updateSubscribeCellDisplay()

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
        } else if Account.subscribed == false {
            self.performSegueWithIdentifier("showSubscribe", sender: self)
        } else {
            UIApplication.sharedApplication().openURL(Account.premoAccoutManagementSite!)
        }
    }

    @IBAction func followOnFacebook(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://www.facebook.com/premonetwork")!)
    }

    @IBAction func followOnTwitter(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://twitter.com/premonetwork")!)
    }

    @IBAction func unwindFromSubscribe(unwindSegue: UIStoryboardSegue) {

    }


    // MARK: - Table

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {

        case 5:
            UIApplication.sharedApplication().openURL(Account.supportSite!)

        case 7:
            guard MFMailComposeViewController.canSendMail() == true else { return }
            let sendFeedbackMailView = MFMailComposeViewController()
            sendFeedbackMailView.mailComposeDelegate = self
            sendFeedbackMailView.setSubject("Feedback")
            sendFeedbackMailView.setToRecipients(["support@premonetwork.com"])
            sendFeedbackMailView.setMessageBody("Hello PREMO, \n\nI have some important feedback to share with you:\n", isHTML: false)
            sendFeedbackMailView.modalPresentationStyle = UIModalPresentationStyle.FullScreen
            sendFeedbackMailView.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
            self.presentViewController(sendFeedbackMailView, animated: true, completion: nil)

        case 9:
            UIApplication.sharedApplication().openURL(Account.premoAboutUsSite!)
            
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
