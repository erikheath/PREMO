//
//  Account.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/16/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import Foundation


class Account: NSObject {

    /**
     Use the subscription enumeration to set and get properties in NSUserDefaults for a user's account.
     */
    private enum subscription: String {
        case JSONWebToken = "jwt"
        case userName = "username"
        case firstName = "firstName"
        case lastName = "lastName"
        case creationDate = "subscriptionCreationDate"
        case expirationDate = "subscriptionExpirationDate"
        case validUntilDate = "subscriptionValidUntilDate"
        case autoRenews = "subscriptionAutoRenews"
        case source = "subscriptionSource"
    }

    /**
     Returns true if the user should be treated as logged in, false otherwise.
     
     - Note: A user's logged in status is determined by the presence of a JSON web token. Because the token may expire at any time, it is possible for a user to have an expired token, but still be treated as being logged in, with this property returning true. To confirm that a user is logged in, call the refresh account method and then query this property.
     */
    static var loggedIn: Bool {
        if NSUserDefaults.standardUserDefaults().stringForKey(subscription.JSONWebToken.rawValue) != nil {
            return true
        }
        return false

    }

    /**
     Returns true if a user has a current active subscription, false otherwise.
     
     - Note: A user's subscription may elapse at anytime, including being due to cancellation. Typically, if a user cancels a subscription, it will be posted to the application from iTunes on the next application launch. If the user has an account from a different source, the account can only be refreshed by making a call to the server. To determine if the user's subscription is active, call the refresh account method and then query this property.
     */
    static var subscribed: Bool {
        if let validUntil = NSUserDefaults.standardUserDefaults().objectForKey(subscription.validUntilDate.rawValue) as? NSDate where validUntil.compare(NSDate()) == NSComparisonResult.OrderedDescending  {
            return true
        }
        return false
    }

    static var authorizationToken: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(subscription.JSONWebToken.rawValue)
    }

    static var userName: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(subscription.userName.rawValue)
    }

    static var firstName: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(subscription.firstName.rawValue)
    }

    static var lastName: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(subscription.lastName.rawValue)
    }

    static var creationDate: NSDate? {
        return NSUserDefaults.standardUserDefaults().objectForKey(subscription.creationDate.rawValue) as? NSDate
    }
    static var expirationDate: NSDate? {
        return NSUserDefaults.standardUserDefaults().objectForKey(subscription.expirationDate.rawValue) as? NSDate
    }
    static var validUntilDate: NSDate? {
        return NSUserDefaults.standardUserDefaults().objectForKey(subscription.validUntilDate.rawValue) as? NSDate
    }

    static var autoRenews: Bool? {
        return NSUserDefaults.standardUserDefaults().boolForKey(subscription.autoRenews.rawValue)
    }

    static var source: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(subscription.source.rawValue)
    }


    /**
     Triggers a series of checks for login and subscription, getting the most current status of the user.
     
     - Throws: In the event of an error - for example a lack of internet connectivity.
     */
    static func refreshAccount() throws -> Void {

    }

    /**
     Processes a JSON payload looking for account information to update. Currently, this will come from calls to playback trailers, features, calls to login, create account, and subscribe.
     */
    static func processAccountPayload(JSONObject: NSDictionary) throws -> Void {
        if let subscription = (JSONObject.objectForKey("payload") as? NSDictionary)!.objectForKey("subscription") as? NSDictionary {
            try self.processSubscriptionPayload(subscription)
        }

    }

    static func processLoginPayload(payload: NSDictionary) throws -> Void {

    }

    static func processSubscriptionPayload(subscription: NSDictionary) throws -> Void {
        guard let subscriptionCreatedString = subscription.objectForKey("created") as? String, let subscriptionExpiresString = subscription.objectForKey("expires") as? String, let subscriptionValidUntilString = subscription.objectForKey("validUntil") as? String, let autoRenewBool = subscription.objectForKey("autoRenew") as? NSNumber, let subscriptionSourceString = subscription.objectForKey("source") else { return }
        /*
        TODO: Handle Subscription Format Error
        In the event of a subscription format error, the user should be notified and given some action to take.
        */

        NSUserDefaults.standardUserDefaults().setObject(subscriptionSourceString, forKey: Account.subscription.source.rawValue)

        let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = enUSPOSIXLocale
        dateFormatter.dateFormat = "yyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        if let subscriptionCreatedDate = dateFormatter.dateFromString(subscriptionCreatedString), let subscriptionExpiresDate = dateFormatter.dateFromString(subscriptionExpiresString), let subscriptionValidUntilDate = dateFormatter.dateFromString(subscriptionValidUntilString) {
            NSUserDefaults.standardUserDefaults().setObject(subscriptionCreatedDate, forKey: Account.subscription.creationDate.rawValue)
            NSUserDefaults.standardUserDefaults().setObject(subscriptionExpiresDate, forKey: Account.subscription.expirationDate.rawValue)
            NSUserDefaults.standardUserDefaults().setObject(subscriptionValidUntilDate, forKey: Account.subscription.validUntilDate.rawValue)
            NSUserDefaults.standardUserDefaults().setBool(autoRenewBool.boolValue, forKey: Account.subscription.autoRenews.rawValue)
            NSUserDefaults.standardUserDefaults().synchronize()
        } else {
            /*
            TODO: Handle Subscription Format Error
            In the event of a subscription format error, the user should be notified and given some action to take.
            */
        }
    }

}