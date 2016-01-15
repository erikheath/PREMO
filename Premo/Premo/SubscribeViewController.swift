//
//  SubscribeViewController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/1/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit
import StoreKit

class SubscribeViewController: UIViewController, SKProductsRequestDelegate {

    @IBOutlet weak var callToActionLabel: UILabel!

    @IBOutlet weak var subscribeOfferLabel: UILabel!

    @IBOutlet weak var subscribeButton: UIButton!

    let request = SKProductsRequest(productIdentifiers: ["30DayFreeTrialVideoSubscription"])

    var products: Array<SKProduct>? = nil

    let iTunesSubscriptionManagement = NSURL(string: "https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions")

    var subscribeOffer = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonLayer = subscribeButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0

        request.delegate = self
        request.start()
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


    @IBAction func skipSubscribe(sender: AnyObject) {
        if (self.navigationController as? AppRoutingNavigationController)!.currentNavigationStack == .credentialStack {
            (self.navigationController as? AppRoutingNavigationController)!.transitionToVideoStack(true)
        } else {
            self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
        }
    }

    @IBAction func subscribe(sender: AnyObject) {
        // Either payment process or go to app store. This may mean I need to check things when coming back to the foreground. Also, I need to put up a progress indicator of some sort. And I need to subscribe to a notification sent by App Delegate for transaction completion.
        switch self.subscribeOffer {
        case 0:
            guard let product = self.products?[0] else {
                // throw some sort of error ?
                return
            }
            let payment = SKMutablePayment(product: product)
            payment.quantity = 1
            SKPaymentQueue.defaultQueue().addPayment(payment)

        case 1:
            guard let _ = self.iTunesSubscriptionManagement else {
                // throw an error ?
                return
            }
            UIApplication.sharedApplication().openURL(self.iTunesSubscriptionManagement!)

        default:
            break // You can not subscribe at this time. throw an error ?
        }
    }

    // MARK: Purchase Management

    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        self.products = response.products

        if response.invalidProductIdentifiers.count != 0 {
            // throw an error or something?
        }
    }

    func configureProductOffer() {

        // Can the user make a payment to subscribe.
        guard SKPaymentQueue.canMakePayments() == true else {
            return // throw some error or show something / do something
        }

        // Determine the offer.
        if NSUserDefaults.standardUserDefaults().stringForKey("subscriptionCreatedDate") != nil {
            // Make the Offer for renewal only.
            self.callToActionLabel.text = "To access full-length features, please re-subscribe to PREMO. Watch films, comedies, originals and more for $4.99/month."
            self.subscribeOfferLabel.text = ""
            self.subscribeButton.setTitle("RENEW NOW", forState: UIControlState.Normal)
            self.subscribeOffer = 1
        }

    }

    // TODO: Fill out these cases
    func purchaseFailed(notification: NSNotification) {
        let alert = UIAlertController(title: "Unable To Subscribe", message: "You have not been subscribed.", preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
        }

        alert.addAction(defaultAction)
        self.presentViewController(alert, animated: true, completion: nil) // This is where you stop the progress indicator.

    }

    func purchaseSucceeded(notification: NSNotification) {
        // Display a dialog that says they're subscribed, stop the progress indicator and then unwind.
        let alert = UIAlertController(title: "Subscription Activated", message: "You have successfully subscribed to PREMO.", preferredStyle: UIAlertControllerStyle.Alert)
        let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action:UIAlertAction) -> Void in
            (self.navigationController as? AppRoutingNavigationController)?.transitionToVideoStack(true)
        }
        alert.addAction(defaultAction)
        self.presentViewController(alert, animated: true, completion: nil) // This is where you stop the progress indicator.
    }

}
