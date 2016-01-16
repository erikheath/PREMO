//
//  LoginTableViewController.swift
//

import UIKit
import FBSDKLoginKit

class LoginTableViewController: UITableViewController, NSURLSessionDelegate, NSURLSessionDataDelegate {


    enum LoginError: Int, ErrorType {
        case unknownError = 5000
        case credentialError = 5001
        case responseError = 5002

        var objectType : NSError {
            get {
                return NSError(domain: "LoginError", code: self.rawValue, userInfo: nil)
            }
        }
    }

    lazy var loginSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)

    weak var currentLoginTask: NSURLSessionDataTask? = nil
    var loginResponse: NSMutableData? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        var buttonLayer = loginButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0

        buttonLayer = facebookLoginButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0



    }

    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        (self.parentViewController as? UINavigationController)?.setNavigationBarHidden(false, animated: false)
        (self.parentViewController as? UINavigationController)?.navigationBar.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        (self.parentViewController as? UINavigationController)?.navigationBar.barTintColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        (self.parentViewController as? UINavigationController)?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        (self.parentViewController as? UINavigationController)?.navigationBar.shadowImage = UIImage()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }


    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var loginButton: UIButton!

    @IBOutlet weak var forgotPasswordButton: UIButton!

    @IBOutlet weak var loginActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var facebookLoginButton: UIButton!

    @IBOutlet weak var needAnAccountButton: UIButton!

    @IBOutlet weak var skipLoginButton: UIButton!

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showCreateAccountFromLogin" && self.navigationController?.childViewControllers.count == 3 {
            // Perform an unwind instead
            self.performSegueWithIdentifier("unwindToCreateAccountFromLogin", sender: self)
            return false
        }

        return true
    }

    @IBAction func skipLogin(sender: AnyObject) {
        if (self.navigationController as? AppRoutingNavigationController)!.currentNavigationStack == .credentialStack {
            (self.navigationController as? AppRoutingNavigationController)!.transitionToVideoStack(true)
        } else {
            self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
        }
    }


    @IBAction func facebookLogin(sender: AnyObject) {

        func processFacebookLogin() {
            guard let loginURL = NSURL(string: "http://lava-dev.premonetwork.com:3000/api/v1/connect/facebook") else { self.presentUnknownFailure(); return }
            let HTTPBodyDictionary: NSDictionary = ["userID": FBSDKAccessToken.currentAccessToken().userID, "accessToken": FBSDKAccessToken.currentAccessToken().tokenString, "deviceID": ((UIApplication.sharedApplication().delegate as? AppDelegate)?.appDeviceID)!, "platform": "ios"]
            self.sendLoginRequest(loginURL, HTTPBodyDictionary: HTTPBodyDictionary)
        }

        self.manageUserInteractions(false)
        if FBSDKAccessToken.currentAccessToken() != nil {
            processFacebookLogin()
            return
        }

        let loginManager = FBSDKLoginManager()
        loginManager.logInWithReadPermissions(["public_profile, email"], fromViewController: self) { (result:FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
            if error != nil {
                self.presentServerFailure()
            }
            if result.isCancelled == true {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.manageUserInteractions(true)
                })
            }
            if result.token != nil {
                processFacebookLogin()
            }
        }
    }

    @IBAction func login(sender: AnyObject) {
        // Manual check to see if the fields are full - or don't make the button pushable until the fields have something in them.
        // Put up timer and disable navigation buttons. Should there be a cancel?
        self.view.endEditing(true)
        self.manageUserInteractions(false)

        guard let userName = emailTextField.text where userName != "", let password = passwordTextField.text where password != "" else { self.presentMissingCredentialError(); return }

        let HTTPBodyDictionary: NSDictionary = ["username": userName, "password": password, "deviceID": ((UIApplication.sharedApplication().delegate as? AppDelegate)?.appDeviceID)!, "platform": "ios"]

        guard let loginURL = NSURL(string: "http://lava-dev.premonetwork.com:3000/api/v1/login") else { self.presentUnknownFailure(); return }

        self.sendLoginRequest(loginURL, HTTPBodyDictionary: HTTPBodyDictionary)

    }

    func sendLoginRequest(loginURL: NSURL, HTTPBodyDictionary: NSDictionary) {
        let lock = NSLock()
        lock.lock()
        if self.currentLoginTask != nil && self.currentLoginTask?.state == NSURLSessionTaskState.Running {
            self.currentLoginTask?.cancel()
            self.currentLoginTask = nil
        }

        self.loginResponse = nil

        let loginRequest = NSMutableURLRequest(URL: loginURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 45.0)
        loginRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")

        do {
            guard NSJSONSerialization.isValidJSONObject(HTTPBodyDictionary) == true else { throw LoginError.credentialError }
            let JSONBodyData: NSData = try NSJSONSerialization.dataWithJSONObject(HTTPBodyDictionary, options: NSJSONWritingOptions.init(rawValue: 0))
            loginRequest.HTTPBody = JSONBodyData
            loginRequest.HTTPMethod = "POST"
            let loginTask = self.loginSession.dataTaskWithRequest(loginRequest)
            self.currentLoginTask = loginTask
            loginTask.resume()

        } catch {
            self.presentUnknownFailure()
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
            self.presentAuthorizationFailure()

        case 500:
            completionHandler(NSURLSessionResponseDisposition.Cancel)
            self.presentServerFailure()

        default:
            completionHandler(NSURLSessionResponseDisposition.Cancel)
            self.presentUnknownFailure()
        }

    }

    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if dataTask.state == NSURLSessionTaskState.Canceling { return }
        if self.loginResponse == nil {
            self.loginResponse = NSMutableData(data: data)
        } else {
            self.loginResponse?.appendData(data)
        }
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if task.state == NSURLSessionTaskState.Canceling { return }
        guard let httpResponse = task.response as? NSHTTPURLResponse else { return }
        do {
            switch httpResponse.statusCode {
            case 200...299:
                guard let response = self.loginResponse else { throw LoginError.responseError }
                guard let JSONResponse = try NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary else { throw LoginError.responseError }
                if (JSONResponse.objectForKey("success") as? NSNumber)!.boolValue == true {
                    self.processSuccessfulLogin(JSONResponse)
                } else if (JSONResponse.objectForKey("success") as? NSNumber)! == false {
                    self.processFailedLogin(JSONResponse)
                } else {
                    throw LoginError.unknownError
                }
            case 400:
                self.presentLoginError()

            default:
                throw LoginError.unknownError
            }
        } catch {
            self.presentUnknownFailure()
        }
    }

    func presentMissingCredentialError() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Login Failed", message: "An email address and password are required. Please try again or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))

            self.loginActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }

    }

    func presentLoginError() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Login Failed", message: "Your email address or password was not recognized. Please try again or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.loginActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentServerFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Login Failure", message: "Your login was unable to be processed. Please try again or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.loginActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentAuthorizationFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Authorization Failure", message: "You are currently not authorized to access these services. Please login to your account or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.loginActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentUnknownFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Login Failure", message: "An unknown error has occurred preventing login. Please check that your internet connection is active or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.loginActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentCustomFailure(message: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Login Failure", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.loginActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }


    func processFailedLogin(payloadDictionary: NSDictionary) {
        do {
            guard let errorDictionary = payloadDictionary.objectForKey("error") as? NSDictionary, let errorCode = errorDictionary.objectForKey("code"), let errorMessage = errorDictionary.objectForKey("message") as? String else { throw LoginError.unknownError }
            var code:Int? = nil
            if errorCode is String { code = Int(errorCode as! String) } else if errorCode is NSNumber { code = (errorCode as! NSNumber).integerValue }
            guard let resolvedCode = code else { throw LoginError.unknownError }
            if resolvedCode == 100 || resolvedCode == 102 || resolvedCode == 103 {
                self.presentCustomFailure(errorMessage)
            } else {
                self.presentUnknownFailure()
            }
        } catch {
            self.presentUnknownFailure()
        }
    }

    func processSuccessfulLogin(payloadDictionary: NSDictionary) {

        guard let jwt = payloadDictionary["payload"]?["jwt"] as? String, let userName = payloadDictionary["payload"]?["member"]?!["email"] as? String, let firstName = payloadDictionary["payload"]?["member"]?!["firstName"] as? String, let lastName = payloadDictionary["payload"]?["member"]?!["lastName"] as? String else { self.presentUnknownFailure(); return }
        NSUserDefaults.standardUserDefaults().setObject(jwt, forKey: "jwt")
        NSUserDefaults.standardUserDefaults().setObject(userName, forKey: "userName")
        NSUserDefaults.standardUserDefaults().setObject(firstName, forKey: "firstName")
        NSUserDefaults.standardUserDefaults().setObject(lastName, forKey: "lastName")

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
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()


        self.displaySuccessAlert()
    }

    func displaySuccessAlert() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "You Are Now Logged In", message: "You have successfully logged into your PREMO account.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
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

            self.loginActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }


    @IBAction func showForgotPassword(sender: AnyObject) {
        guard let supportSite = NSURL(string: "http://www.premonetwork.com/support") else { return }
        UIApplication.sharedApplication().openURL(supportSite)
    }

    @IBAction func endEditingInView(sender: AnyObject) {
        self.view.endEditing(true)
    }

    @IBAction func emailEditingEnded(sender: AnyObject) {
        passwordTextField.becomeFirstResponder()
        emailTextField.resignFirstResponder()
    }

    func manageUserInteractions(enabled: Bool) {

        if enabled == true {
            self.loginActivityIndicator.stopAnimating()
        } else {
            self.loginActivityIndicator.startAnimating()
        }
        
        emailTextField.userInteractionEnabled = enabled
        passwordTextField.userInteractionEnabled = enabled
        loginButton.userInteractionEnabled = enabled
        forgotPasswordButton.userInteractionEnabled = enabled
        needAnAccountButton.userInteractionEnabled = enabled
        skipLoginButton.userInteractionEnabled = enabled
        self.navigationItem.backBarButtonItem?.enabled = enabled
        
    }
}
