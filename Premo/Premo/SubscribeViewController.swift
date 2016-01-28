//
//  SubscribeViewController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/1/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit
import StoreKit

class SubscribeViewController: UIViewController, SKProductsRequestDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate {

    // MARK: - PROPERTIES


    // MARK: UI Outlets
    @IBOutlet weak var callToActionLabel: UILabel!

    @IBOutlet weak var subscribeButton: UIButton!

    @IBOutlet weak var subscribeActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var skipSubscribeButton: UIButton!


    // MARK: Purchase & Subscription Management

    let request = SKProductsRequest(productIdentifiers: ["30DayFreeTrial"])

    var products: Array<SKProduct>? = nil

    var subscribeOffer = 0


    // MARK: System Interaction Management

    var currentMonitor: NSTimer? = nil



    //MARK: - OBJECT LIFECYCYLE


    // MARK: UI Setup & Teardown

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.configureNavigationItemAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureNavigationItemAppearance()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "  ", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = ""
            self.navigationItem.hidesBackButton = true
        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = false
            PremoStyleTemplate.styleFullScreenNavBar(navbarController.navigationBar)

        }
    }

    func buttonFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 14.0)!
        //        let newFont = UIFont.systemFontOfSize(20)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 14.0)

    }

    func skipFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 14.0)!
        //        let newFont = UIFont.systemFontOfSize(20)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 14.0)

    }


    func styledTagline(tagline: NSAttributedString) -> NSAttributedString {
        let mutableTagline = NSMutableAttributedString(attributedString: tagline)
        mutableTagline.addAttribute(NSForegroundColorAttributeName, value: UIColor(colorLiteralRed: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0), range: NSMakeRange(0, mutableTagline.length))
        mutableTagline.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.5), range: NSMakeRange(0, mutableTagline.length))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.defaultParagraphStyle())
        paragraphStyle.alignment = .Center
        paragraphStyle.paragraphSpacing = 1
        mutableTagline.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, mutableTagline.length))


        return mutableTagline
    }

    func styledButtonText(buttonText: String) -> NSAttributedString {
        let mutableButtonText = NSMutableAttributedString(string: buttonText)
        mutableButtonText.addAttribute(NSFontAttributeName, value: self.buttonFont(), range: NSMakeRange(0, mutableButtonText.length))
        mutableButtonText.addAttribute(NSForegroundColorAttributeName, value: UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), range: NSMakeRange(0, mutableButtonText.length))
        mutableButtonText.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.5), range: NSMakeRange(0, mutableButtonText.length))

        return mutableButtonText
    }

    func styledSkipText(skipText: String) -> NSAttributedString {
        let mutableSkipText = NSMutableAttributedString(string: skipText)
        mutableSkipText.addAttribute(NSFontAttributeName, value: self.skipFont(), range: NSMakeRange(0, mutableSkipText.length))
        mutableSkipText.addAttribute(NSForegroundColorAttributeName, value: UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), range: NSMakeRange(0, mutableSkipText.length))
        mutableSkipText.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.5), range: NSMakeRange(0, mutableSkipText.length))

        return mutableSkipText
    }



    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonLayer = subscribeButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0

        self.callToActionLabel.attributedText = self.styledTagline(self.callToActionLabel.attributedText!)

        request.delegate = self
        manageUserInteractions(false)
        self.configureProductOffer()

        if SKPaymentQueue.canMakePayments() == true {
            self.currentMonitor = NSTimer.scheduledTimerWithTimeInterval(20.0, target: self, selector: "productRequestTimedOut:", userInfo: nil, repeats: false)
            request.start()
        } else {
            self.presentPurchaseAuthorizationFailure()
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseRequestPurchasing:", name: TransactionProcessor.TransactionStatusNotification.purchasing.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseRequestDeferred:", name: TransactionProcessor.TransactionStatusNotification.deferred.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentPurchaseFailed:", name: TransactionProcessor.TransactionStatusNotification.failed.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseRequestSucceeded:", name: TransactionProcessor.TransactionStatusNotification.purchased.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentReceiptProcessingError:", name: RegistrationProcessor.RegistrationStatusNotification.receiptError.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentRegistrationFailure:", name: RegistrationProcessor.RegistrationStatusNotification.communicationError.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "presentPurchaseSuccessful:", name: RegistrationProcessor.RegistrationStatusNotification.registered.rawValue, object: nil)

        /*
        TODO: Add timeouts for each step?
        It's possible that this could time out. But how would I know to refresh the interface?
        */

        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()

    }



    override func viewWillAppear(animated: Bool) {
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        (self.revealViewController() as? SlideController)!.blackStatusBarBackgroundView?.backgroundColor = UIColor.clearColor()

        super.viewWillAppear(animated)

    }

    override func viewWillDisappear(animated: Bool) {
        let lock = NSLock()
        lock.lock()
        if self.currentMonitor != nil {
            self.currentMonitor?.invalidate()
            self.currentMonitor = nil
        }
        lock.unlock()

        super.viewWillDisappear(animated)
    }

    func configureProductOffer() {

        // Determine the offer.
        if Account.creationDate != nil {
            // Make the Offer for renewal only.
            self.subscribeButton.setAttributedTitle(self.styledButtonText("RENEW NOW"), forState: UIControlState.Normal)
            self.subscribeOffer = 1
        } else {
            self.subscribeOffer = 0
            self.subscribeButton.setAttributedTitle(self.styledButtonText("START YOUR 30-DAY TRIAL"), forState: UIControlState.Normal)
        }

    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }


    // MARK: System Interaction Management

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func productRequestTimedOut(timer: NSTimer) {
        // the product request could not be completed?
        let lock = NSLock()
        lock.lock()
        if self.currentMonitor != nil {
            self.currentMonitor = nil
            self.presentProductRequestFailure()
        }
        lock.unlock()
    }

    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        do {
            let lock = NSLock()
            lock.lock()
            if self.currentMonitor == nil { return }
            self.currentMonitor = nil
            defer { lock.unlock() }
        }
        if response.products.count != 1 { self.presentProductRequestFailure(); return }
        self.products = response.products
        self.manageUserInteractions(true)

    }



    // MARK: - USER INTERFACE EVENTS

    // MARK: System Interaction Management
    // System driven user interface changes, usually resulting from system level events or responses to user initiated events such as navigation, tapping an asynchronous control, etc.

    func manageUserInteractions(enabled: Bool) {

        if enabled == true {
            self.subscribeActivityIndicator.stopAnimating()
        } else {
            self.subscribeActivityIndicator.startAnimating()
        }

        subscribeButton.userInteractionEnabled = enabled
        skipSubscribeButton.userInteractionEnabled = enabled
        self.navigationItem.backBarButtonItem?.enabled = enabled

    }

    func presentProductRequestFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Unable to Access the App Store", message: "PREMO was unable to access the App Store. Please try again or contact PREMO customer support.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.subscribeActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentiTunesAccessFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "An unknown error has occurred.", message: "Please check that your internet connection is active or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.subscribeActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentPurchaseAuthorizationFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Purchase Authorization Failure", message: "The current iTunes account is not authorized to make purchases. To enable purchasing, please visit your iTunes account to make changes to your payment settings or for more information.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Go to iTunes", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                guard let appRouter = self.navigationController as? AppRoutingNavigationController else { return } // There is some error to handle here
                switch appRouter.currentNavigationStack {
                case .accountStack:
                    self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
                case .credentialStack:
                    appRouter.transitionToVideoStack(true)
                case .videoStack:
                    self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
                }
            }))
            alert.addAction(UIAlertAction(title: "Skip for now", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in

            }))
            self.subscribeActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func purchaseRequestPurchasing(notification: NSNotification) -> Void {
        //        self.subscribeOfferLabel.text = "Purchasing"
    }

    func purchaseRequestDeferred(notification: NSNotification) -> Void {
        //        self.subscribeOfferLabel.text = "Processing"
    }

    func purchaseRequestSucceeded(notification: NSNotification) -> Void {
        //        self.subscribeOfferLabel.text = "Purchase Completed. Registering Subscription with PREMO."
    }

    func presentPurchaseFailed(notification: NSNotification) -> Void {
        let alert = UIAlertController(title: "Unable To Subscribe", message: "You have not been subscribed.", preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            self.subscribe(self)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action: UIAlertAction) -> Void in
            self.manageUserInteractions(true)
        }

        alert.addAction(defaultAction)
        alert.addAction(cancelAction)
        self.presentViewController(alert, animated: true, completion: nil)
        self.configureProductOffer()
        self.subscribeActivityIndicator.stopAnimating()

    }

    func presentRegistrationFailure(notification: NSNotification) -> Void {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "A subscription registration error has occurred.", message: "Your subscription purchase was successful but registration has failed. Please contact PREMO support to activate your subscription.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.subscribeActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentReceiptProcessingError(notification: NSNotification) -> Void {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "A subscription registration error has occurred.", message: "Your subscription purchase appears to be successful, but your receipt could not be read. Please contact PREMO support to activate your subscription.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.subscribeActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentPurchaseSuccessful(notification: NSNotification) -> Void {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Subscription Activated", message: "You have successfully subscribed to PREMO.", preferredStyle: UIAlertControllerStyle.Alert)
            let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
                guard let appRouter = self.navigationController as? AppRoutingNavigationController else { return }
                /*
                TODO: This is a fatal error
                This should never occur, but in the event of a fatal error, something needs to be displayed and the app should exit.
                */
                switch appRouter.currentNavigationStack {
                case .accountStack:
                    self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
                case .credentialStack:
                    appRouter.transitionToVideoStack(true)
                case .videoStack:
                    self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
                }
            }
            alert.addAction(defaultAction)
            self.presentViewController(alert, animated: true, completion: nil)
            self.subscribeActivityIndicator.stopAnimating()
        }
    }


    // MARK: User Actions

    @IBAction func skipSubscribe(sender: AnyObject) {
        if (self.navigationController as? AppRoutingNavigationController)!.currentNavigationStack == .credentialStack {
            (self.navigationController as? AppRoutingNavigationController)!.transitionToVideoStack(true)
        } else {
            self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
        }
    }

    @IBAction func subscribe(sender: AnyObject) {
        // Either process payment or go to app store. This may mean I need to check things when coming back to the foreground. Also, I need to put up a progress indicator of some sort. And I need to subscribe to a notification sent by App Delegate for transaction completion.
        self.manageUserInteractions(false)
        switch self.subscribeOffer {
        case 0:
            guard let product = self.products?[0] else {
                self.presentProductRequestFailure()
                return
            }
            let payment = SKMutablePayment(product: product)
            payment.quantity = 1
            SKPaymentQueue.defaultQueue().addPayment(payment)
            
        case 1:
            guard let _ = Account.iTunesSubscriptionManagement else {
                self.presentiTunesAccessFailure()
                return
            }
            UIApplication.sharedApplication().openURL(Account.iTunesSubscriptionManagement!)
            self.manageUserInteractions(true)
            
        default:
            self.presentiTunesAccessFailure()
        }
    }
    
}
