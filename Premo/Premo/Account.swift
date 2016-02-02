//
//  Account.swift
//

import Foundation


class Account: NSObject {

    /**
     Use the subscription enumeration to set and get properties in NSUserDefaults for a user's account.
     */
    private enum AccountInfo: String {
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
     Account errors that can be thrown by the Account object while processing incoming JSON data.
     */
    enum AccountError: Int, ErrorType {
        case unknownError = 5000
        case invalidSubscriptionFormat = 5001
        case creationError = 5002
        case invalidMemberFormat = 5003

        var objectType : NSError {
            get {
                return NSError(domain: "AccountError", code: self.rawValue, userInfo: nil)
            }
        }

        var description: String {
            var errorString: String = ""
            switch self._code {
            case 5000:
                errorString = "Unknown Error"
            case 5001:
                errorString = "Invalid Subscription Format Error"
            case 5002:
                errorString = "Creation Error"
            case 5003:
                errorString = " Invalid Member Format Error"
            default:
                errorString = "Unknown Error"
            }
            return errorString
        }
    }

    static let supportSite = NSURL(string: "/support", relativeToURL: AppDelegate.PREMOMainURL)
    static let iTunesSubscriptionManagement = NSURL(string: "https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/manageSubscriptions")
    static let premoAccoutManagementSite = AppDelegate.PREMOMainURL
    static let premoForgotPasswordSite = NSURL(string: "/web/#/forgot", relativeToURL: AppDelegate.PREMOURL)
    /**
     The url path used for all premo member info requests
     */
    static let memberPath = "/api/v1/member"
    static let logoutPath = "/api/v1/logout"


    /**
     Returns true if the user should be treated as logged in, false otherwise.
     
     - Note: A user's logged in status is determined by the presence of a JSON web token. Because the token may expire at any time, it is possible for a user to have an expired token, but still be treated as being logged in, with this property returning true. To confirm that a user is logged in, call the refresh account method and then query this property.
     */
    static var loggedIn: Bool {
        if NSUserDefaults.standardUserDefaults().stringForKey(AccountInfo.JSONWebToken.rawValue) != nil {
            return true
        }
        return false

    }

    /**
     Returns true if a user has a current active subscription, false otherwise.
     
     - Note: A user's subscription may elapse at anytime, including being due to cancellation. Typically, if a user cancels a subscription, it will be posted to the application from iTunes on the next application launch. If the user has an account from a different source, the account can only be refreshed by making a call to the server. To determine if the user's subscription is active, call the refresh account method and then query this property.
     */
    static var subscribed: Bool {
        if let validUntil = NSUserDefaults.standardUserDefaults().objectForKey(AccountInfo.validUntilDate.rawValue) as? NSDate where validUntil.compare(NSDate()) == NSComparisonResult.OrderedDescending  {
            return true
        }
        return false
    }

    static var authorizationToken: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(AccountInfo.JSONWebToken.rawValue)
    }

    static var userName: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(AccountInfo.userName.rawValue)
    }

    static var firstName: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(AccountInfo.firstName.rawValue)
    }

    static var lastName: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(AccountInfo.lastName.rawValue)
    }

    static var creationDate: NSDate? {
        return NSUserDefaults.standardUserDefaults().objectForKey(AccountInfo.creationDate.rawValue) as? NSDate
    }
    static var expirationDate: NSDate? {
        return NSUserDefaults.standardUserDefaults().objectForKey(AccountInfo.expirationDate.rawValue) as? NSDate
    }
    static var validUntilDate: NSDate? {
        return NSUserDefaults.standardUserDefaults().objectForKey(AccountInfo.validUntilDate.rawValue) as? NSDate
    }

    static var autoRenews: Bool? {
        return NSUserDefaults.standardUserDefaults().boolForKey(AccountInfo.autoRenews.rawValue)
    }

    static var source: String? {
        return NSUserDefaults.standardUserDefaults().stringForKey(AccountInfo.source.rawValue)
    }

    /**
     Removes the user's device from being counted by the PREMO service as an active device. Called as part of the logout process.
     */
    static func removeDeviceFromService() {
        if self.loggedIn == true {
            do {
                let logoutRequest = try NSMutableURLRequest.PREMOURLRequest(self.memberPath, method: NSMutableURLRequest.PREMORequestMethod.GET, HTTPBody: nil, authorizationRequired: true)
                self.sendLogoutRequest(logoutRequest)
            } catch { self.clearAccountSettings() }
        } else {
            self.clearAccountSettings()
        }
    }

    private static func sendLogoutRequest(logoutRequest: NSMutableURLRequest) -> Void {
        let logoutRequestTask = NSURLSession.sharedSession().dataTaskWithRequest(logoutRequest, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

            guard error == nil else { return }

            guard let httpResponse = response as? NSHTTPURLResponse else { return }

            // Placeholder for more advanced response error handling.
            switch httpResponse.statusCode {

            default:
                break

            }
        })

        logoutRequestTask.resume()
    }

    /**
     Clears all account settings, effectively logging the user out on the device. This method is always called by removeDeviceFromService after it completes.
     */
    static func clearAccountSettings() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.JSONWebToken.rawValue)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.userName.rawValue)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.firstName.rawValue)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.lastName.rawValue)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.source.rawValue)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.creationDate.rawValue)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.expirationDate.rawValue)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.validUntilDate.rawValue)
        NSUserDefaults.standardUserDefaults().removeObjectForKey(AccountInfo.autoRenews.rawValue)
    }

    /**
     Triggers a series of checks for login and subscription, getting the most current status of the user or clearing the current stale account data.
     
     - Throws: In the event of an error - for example a lack of internet connectivity.
     */
    static func refreshAccount() throws -> Void {
        if self.loggedIn == true {
            do {
                let refreshRequest = try NSMutableURLRequest.PREMOURLRequest(self.memberPath, method: NSMutableURLRequest.PREMORequestMethod.GET, HTTPBody: nil, authorizationRequired: true)
                self.sendRefreshRequest(refreshRequest)
            } catch { self.clearAccountSettings() }
        } else {
            self.clearAccountSettings()
        }
    }

    private static func sendRefreshRequest(refreshRequest: NSMutableURLRequest) -> Void {
            let registrationRequestTask = NSURLSession.sharedSession().dataTaskWithRequest(refreshRequest, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

                guard error == nil else { return }

                guard let httpResponse = response as? NSHTTPURLResponse else { return }

                guard let responseData = data else { return }

                switch httpResponse.statusCode {
                case 200...299:
                    self.processRefreshResponse(responseData)

                case 401:
                    self.clearAccountSettings() // The JSON Web token was expired and the user is not logged in.

                default:
                    break
                    
                }
            })
            
            registrationRequestTask.resume()
    }

    /**
     Processes the response data from a refresh request.
     */
    private static func processRefreshResponse(refreshData: NSData) {
        do {
            guard let JSONObject = try NSJSONSerialization.JSONObjectWithData(refreshData, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary else { return }

            guard let success = JSONObject.objectForKey("success") where (success as? NSNumber)!.boolValue == true else {
                self.clearAccountSettings()
                return
            }

            guard let _ = JSONObject.objectForKey("payload") as? NSDictionary else {
                return
            }

            try self.processAccountPayload(JSONObject)

        } catch {
            self.clearAccountSettings()
            return
        }

    }

    /**
     Processes a JSON payload looking for account information to update. Currently, this will come from calls to playback trailers, features, calls to login, create account, and subscribe. It is not an error to call this with partial information, however subscription related updates require a complete subscription object.
     
     - parameter JSONObject: Any valid JSONDictionary that contains account information in the standard PREMO formats.
     
     -
     */
    static func processAccountPayload(JSONObject: NSDictionary) throws -> Void {
        defer {
            NSUserDefaults.standardUserDefaults().synchronize()
            objc_sync_exit(self)
        }

        objc_sync_enter(self)

        do {
            guard let payload = JSONObject.objectForKey("payload") as? NSDictionary else {
                return
            }

            self.processAuthorizationPayload(payload)

            if let member = payload.objectForKey("member") as? NSDictionary {
                try self.processMemberPayload(member)
            }

            if let subscription = payload.objectForKey("subscription") as? NSDictionary {
                try self.processSubscriptionPayload(subscription)
            }
        }

    }

    /**
     Processes a JSON Object representing a PREMO authentication token. If the token is not present in the dictionary, no change to user defaults is made.

     - parameter subscription: A valid subscription object as an NSDictionary.

     */
    private static func processAuthorizationPayload(payload: NSDictionary) -> Void {
        if let jwt = payload.objectForKey("jwt") as? String {
            NSUserDefaults.standardUserDefaults().setObject(jwt, forKey: AccountInfo.JSONWebToken.rawValue)
        }
    }

    /**
     Processes a JSON Object representing a PREMO member.

     - parameter member: A valid member object as an NSDictionary.

     - throws: If any of the required member parameters are missing, throws an invalid member format error.
     */
    private static func processMemberPayload(member: NSDictionary) throws -> Void {
        guard let userName = member.objectForKey("email") as? String, let firstName = member.objectForKey("firstName") as? String, let lastName = member.objectForKey("lastName") as? String else { throw AccountError.invalidMemberFormat }
        NSUserDefaults.standardUserDefaults().setObject(userName, forKey: "userName")
        NSUserDefaults.standardUserDefaults().setObject(firstName, forKey: "firstName")
        NSUserDefaults.standardUserDefaults().setObject(lastName, forKey: "lastName")
    }


    /**
     Processes a JSON Object representing a PREMO subscription.
     
     - parameter subscription: A valid subscription object as an NSDictionary.
     
     - throws: If any of the required subscription parameters are missing, throws an invalid subscription format error.
     */
    private static func processSubscriptionPayload(subscription: NSDictionary) throws -> Void {
        guard let subscriptionCreatedString = subscription.objectForKey("created") as? String, let subscriptionExpiresString = subscription.objectForKey("expires") as? String, let subscriptionValidUntilString = subscription.objectForKey("validUntil") as? String, let autoRenewBool = subscription.objectForKey("autoRenew") as? NSNumber, let subscriptionSourceString = subscription.objectForKey("source") else { throw AccountError.invalidSubscriptionFormat }

        NSUserDefaults.standardUserDefaults().setObject(subscriptionSourceString, forKey: Account.AccountInfo.source.rawValue)

        let enUSPOSIXLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = enUSPOSIXLocale
        dateFormatter.dateFormat = "yyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        if let subscriptionCreatedDate = dateFormatter.dateFromString(subscriptionCreatedString), let subscriptionExpiresDate = dateFormatter.dateFromString(subscriptionExpiresString), let subscriptionValidUntilDate = dateFormatter.dateFromString(subscriptionValidUntilString) {
            NSUserDefaults.standardUserDefaults().setObject(subscriptionCreatedDate, forKey: Account.AccountInfo.creationDate.rawValue)
            NSUserDefaults.standardUserDefaults().setObject(subscriptionExpiresDate, forKey: Account.AccountInfo.expirationDate.rawValue)
            NSUserDefaults.standardUserDefaults().setObject(subscriptionValidUntilDate, forKey: Account.AccountInfo.validUntilDate.rawValue)
            NSUserDefaults.standardUserDefaults().setBool(autoRenewBool.boolValue, forKey: Account.AccountInfo.autoRenews.rawValue)
        } else {
            throw AccountError.invalidSubscriptionFormat
        }
    }

}