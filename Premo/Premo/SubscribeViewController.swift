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

    @IBOutlet weak var callToActionLabel: UILabel!

    @IBOutlet weak var subscribeOfferLabel: UILabel!

    @IBOutlet weak var subscribeButton: UIButton!

    @IBOutlet weak var subscribeActivityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var skipSubscribeButton: UIButton!

    let request = SKProductsRequest(productIdentifiers: ["30DayFreeTrialVideoSubscription"])

    var products: Array<SKProduct>? = nil

    let iTunesSubscriptionManagement = NSURL(string: "https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions")

    var subscribeOffer = 0

    var currentMonitor: NSTimer? = nil

    enum RegistrationError: Int, ErrorType {
        case unknownError = 5000
        case credentialError = 5001
        case responseError = 5002

        var objectType : NSError {
            get {
                return NSError(domain: "RegistrationError", code: self.rawValue, userInfo: nil)
            }
        }
    }

    lazy var registrationSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)

    weak var currentRegistrationTask: NSURLSessionDataTask? = nil
    var registrationResponse: NSMutableData? = nil


    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonLayer = subscribeButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0

        request.delegate = self
        manageUserInteractions(false)
        self.configureProductOffer()

        if SKPaymentQueue.canMakePayments() == true {
            self.currentMonitor = NSTimer.scheduledTimerWithTimeInterval(20.0, target: self, selector: "productRequestTimedOut:", userInfo: nil, repeats: false)
            request.start()
        } else {
            self.presentPurchaseAuthorizationFailure()
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseRequestPurchasing:", name: AppDelegate.TransactionStatusNotification.purchasing.rawValue, object: UIApplication.sharedApplication().delegate)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseRequestDeferred:", name: AppDelegate.TransactionStatusNotification.deferred.rawValue, object: UIApplication.sharedApplication().delegate)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseRequestFailed:", name: AppDelegate.TransactionStatusNotification.failed.rawValue, object: UIApplication.sharedApplication().delegate)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "purchaseRequestSucceeded:", name: AppDelegate.TransactionStatusNotification.purchased.rawValue, object: UIApplication.sharedApplication().delegate)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        (self.parentViewController as? UINavigationController)?.setNavigationBarHidden(true, animated: true)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)

    }

    func configureProductOffer() {

        // Determine the offer.
        if NSUserDefaults.standardUserDefaults().stringForKey("subscriptionCreatedDate") != nil {
            // Make the Offer for renewal only.
            self.callToActionLabel.text = "To access full-length features, please re-subscribe to PREMO. Watch films, comedies, originals and more for $4.99/month."
            self.subscribeOfferLabel.text = ""
            self.subscribeButton.setTitle("RENEW NOW", forState: UIControlState.Normal)
            self.subscribeOffer = 1
        }
        
    }

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


    @IBAction func skipSubscribe(sender: AnyObject) {
        if (self.navigationController as? AppRoutingNavigationController)!.currentNavigationStack == .credentialStack {
            (self.navigationController as? AppRoutingNavigationController)!.transitionToVideoStack(true)
        } else {
            self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
        }
    }


    // MARK: - PURCHASE MANAGEMENT

    // MARK: Product Request
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

    // MARK: Purchase Request

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
            guard let _ = self.iTunesSubscriptionManagement else {
                self.presentiTunesAccessFailure()
                return
            }
            UIApplication.sharedApplication().openURL(self.iTunesSubscriptionManagement!)
            self.manageUserInteractions(true)

        default:
            self.presentiTunesAccessFailure()
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

    func purchaseRequestPurchasing(notification: NSNotification) {
        self.subscribeOfferLabel.text = "Purchasing"
    }

    func purchaseRequestDeferred(notification: NSNotification) {
        self.subscribeOfferLabel.text = "Processing"
    }

    func purchaseRequestFailed(notification: NSNotification) {
        self.configureProductOffer()
        self.purchaseFailed(notification)
    }

    func purchaseRequestSucceeded(notification: NSNotification) {
        self.subscribeOfferLabel.text = "Purchase Completed"
        self.purchaseSucceeded(notification)
    }


    func purchaseFailed(notification: NSNotification) {
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
        self.subscribeActivityIndicator.stopAnimating()

    }

    func purchaseSucceeded(notification: NSNotification) {

        // Register with the PREMO server
        guard let receiptURL = NSBundle.mainBundle().appStoreReceiptURL, let receiptData = NSData(contentsOfURL: receiptURL), let transaction = notification.object as? SKPaymentTransaction else { self.presentRegistrationFailure(); return }

        let HTTPBodyDictionary: NSDictionary = [ "token": receiptData, "platform": "ios"]

        guard let registrationURL = NSURL(string: "http://lava-dev.premonetwork.com:3000/api/v1/subscription/receipt") else { self.presentRegistrationFailure(); return }

        self.sendRegistrationRequest(registrationURL, HTTPBodyDictionary: HTTPBodyDictionary, transaction: transaction)

    }

    func presentRegistrationFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "A subscription registration error has occurred.", message: "Your subscription purchase was successful but registration has failed. Please contact PREMO support to activate your subscription.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.subscribeActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    // MARK: Purchase Registration

    func sendRegistrationRequest(registrationURL: NSURL, HTTPBodyDictionary: NSDictionary, transaction: SKPaymentTransaction) {
        let lock = NSLock()
        lock.lock()
        if self.currentRegistrationTask != nil && self.currentRegistrationTask?.state == NSURLSessionTaskState.Running {
            self.currentRegistrationTask?.cancel()
            self.currentRegistrationTask = nil
        }

        self.registrationResponse = nil

        let registrationRequest = NSMutableURLRequest(URL: registrationURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 45.0)
        registrationRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
        registrationRequest.setValue(NSUserDefaults.standardUserDefaults().stringForKey("jwt"), forHTTPHeaderField: "Authorization")
        NSURLProtocol.setProperty(transaction, forKey: "PurchaseTransaction", inRequest: registrationRequest)
        do {
            guard NSJSONSerialization.isValidJSONObject(HTTPBodyDictionary) == true else { throw RegistrationError.credentialError }
            let JSONBodyData: NSData = try NSJSONSerialization.dataWithJSONObject(HTTPBodyDictionary, options: NSJSONWritingOptions.init(rawValue: 0))
            registrationRequest.HTTPBody = JSONBodyData
            registrationRequest.HTTPMethod = "POST"
            let registrationTask = self.registrationSession.dataTaskWithRequest(registrationRequest)
            self.currentRegistrationTask = registrationTask
            registrationTask.resume()

        } catch {
            self.presentRegistrationFailure()
        }

        defer {
            lock.unlock()
        }

    }


    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        // Test the response type: 200 - 299 is acceptable to continue
        // 400 - Bad Request. Ideally, client side will handle this, but for now, use the server.
        // 401 - A secure resource was requested but an authorization token was not provided. Likely because the user must login. However, the user should be directed to login? subscribe?
        // 500 - An unexpected error occurred on the server. What to do?
        if dataTask.state == NSURLSessionTaskState.Canceling { completionHandler(NSURLSessionResponseDisposition.Cancel); return }
        guard let httpResponse = response as? NSHTTPURLResponse else { completionHandler(NSURLSessionResponseDisposition.Cancel); return } // This is an unknown, unrequested response type.
        switch httpResponse.statusCode {
        case 200...299:
            completionHandler(NSURLSessionResponseDisposition.Allow)
        case 400:
            completionHandler(NSURLSessionResponseDisposition.Allow)

        case 401:
            completionHandler(NSURLSessionResponseDisposition.Cancel)
            self.presentRegistrationFailure()

        case 500:
            completionHandler(NSURLSessionResponseDisposition.Cancel)
            self.presentRegistrationFailure()

        default:
            completionHandler(NSURLSessionResponseDisposition.Cancel)
            self.presentRegistrationFailure()
        }

    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if dataTask.state == NSURLSessionTaskState.Canceling { return }
        if self.registrationResponse == nil {
            self.registrationResponse = NSMutableData(data: data)
        } else {
            self.registrationResponse?.appendData(data)
        }
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if task.state == NSURLSessionTaskState.Canceling { return }
        guard let httpResponse = task.response as? NSHTTPURLResponse else { return }
        do {
            switch httpResponse.statusCode {
            case 200...299:
                guard let response = self.registrationResponse, let request = task.originalRequest else { throw RegistrationError.responseError }
                guard let JSONResponse = try NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary else { throw RegistrationError.responseError }
                if (JSONResponse.objectForKey("success") as? NSNumber)!.boolValue == true {
                    self.processSuccessfulPurchase(JSONResponse, originalRequest: request)
                } else if (JSONResponse.objectForKey("success") as? NSNumber)! == false {
                    self.presentRegistrationFailure()
                } else {
                    throw RegistrationError.unknownError
                }
            case 400:
                self.presentRegistrationFailure()

            default:
                throw RegistrationError.unknownError
            }
        } catch {
            self.presentRegistrationFailure()
        }
    }

    func processSuccessfulPurchase(payloadDictionary: NSDictionary, originalRequest: NSURLRequest) {

        if let subscriptionSource = payloadDictionary["payload"]?["subscription"]?!["source"] as? String, let subscriptionCreated = payloadDictionary["payload"]?["subscription"]?!["created"] as? String, let subscriptionExpires = payloadDictionary["payload"]?["subscription"]?!["expires"] as? String, let subscriptionValidUntil = payloadDictionary["payload"]?["subscription"]?!["validUntil"] as? String, let subscriptionAutoRenew = payloadDictionary["payload"]?["subscription"]?!["autoRenew"] as? NSNumber {
            NSUserDefaults.standardUserDefaults().setObject(subscriptionSource, forKey: "subscriptionSource")

            let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
            let dateFormatter = NSDateFormatter()
            dateFormatter.locale = enUSPOSIXLocale
            dateFormatter.dateFormat = "yyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
            if let subscriptionCreatedDate = dateFormatter.dateFromString(subscriptionCreated), let subscriptionExpiresDate = dateFormatter.dateFromString(subscriptionExpires), let subscriptionValidUntilDate = dateFormatter.dateFromString(subscriptionValidUntil) {
                NSUserDefaults.standardUserDefaults().setObject(subscriptionCreatedDate, forKey: "subscriptionCreatedDate")
                NSUserDefaults.standardUserDefaults().setObject(subscriptionExpiresDate, forKey: "subscriptionExpiresDate")
                NSUserDefaults.standardUserDefaults().setObject(subscriptionValidUntilDate, forKey: "subscriptionValidUntilDate")
                NSUserDefaults.standardUserDefaults().setBool(subscriptionAutoRenew.boolValue, forKey: "subscriptionAutoRenew")
            }

            NSUserDefaults.standardUserDefaults().synchronize()
            guard let transaction = NSURLProtocol.propertyForKey("PurchaseTransaction", inRequest: originalRequest) as? SKPaymentTransaction else { self.presentRegistrationFailure(); return }
            SKPaymentQueue.defaultQueue().finishTransaction(transaction)
        } else {
            self.presentRegistrationFailure()
        }

        self.presentPurchaseSuccessful()
    }

    func presentPurchaseSuccessful() {

        // Display a dialog that says they're subscribed, stop the progress indicator and then unwind.
        let alert = UIAlertController(title: "Subscription Activated", message: "You have successfully subscribed to PREMO.", preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            guard let appRouter = self.navigationController as? AppRoutingNavigationController else { return } // There is some error to handle here
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
