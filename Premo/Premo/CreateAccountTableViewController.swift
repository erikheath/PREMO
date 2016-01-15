//
//  CreateAccountTableViewController.swift
//

import UIKit
import FBSDKLoginKit

class CreateAccountTableViewController: UITableViewController, NSURLSessionDelegate, NSURLSessionDataDelegate {

    @IBOutlet weak var signupButton: UIButton!

    @IBOutlet weak var facebookSignupButton: UIButton!
    
    enum SignUpError: Int, ErrorType {
        case unknownError = 5000
        case credentialError = 5001
        case responseError = 5002

        var objectType : NSError {
            get {
                return NSError(domain: "SignUpError", code: self.rawValue, userInfo: nil)
            }
        }
    }

    lazy var signUpSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)

    weak var currentSignUpTask: NSURLSessionDataTask? = nil
    var signUpResponse: NSMutableData? = nil


    override func viewDidLoad() {
        super.viewDidLoad()

        var buttonLayer = signupButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0

        buttonLayer = facebookSignupButton.layer
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

    @IBAction func unwindToCreateAccountFromLogin(sender: UIStoryboardSegue) {

    }

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showLoginFromCreateAccount" && self.navigationController?.childViewControllers.count == 3 {
            // Perform an unwind instead
            self.performSegueWithIdentifier("unwindToLoginFromCreateAccount", sender: self)
            return false
        }

        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var firstNameTextField: UITextField!

    @IBOutlet weak var lastNameTextField: UITextField!

    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var gotoLoginButton: UIButton!

    @IBOutlet weak var signupActivityIndicator: UIActivityIndicatorView!


    @IBAction func facebookSignup(sender: AnyObject) {
        func processFacebookLogin() {
            guard let loginURL = NSURL(string: "http://lava-dev.premonetwork.com:3000/api/v1/connect/facebook") else { self.presentUnknownFailure(); return }
            let HTTPBodyDictionary: NSDictionary = ["userID": FBSDKAccessToken.currentAccessToken().userID, "accessToken": FBSDKAccessToken.currentAccessToken().tokenString, "deviceID": ((UIApplication.sharedApplication().delegate as? AppDelegate)?.appDeviceID)!, "platform": "ios"]
            self.sendSignupRequest(loginURL, HTTPBodyDictionary: HTTPBodyDictionary)
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

    @IBAction func signUp(sender: AnyObject) {
        // Manual check to see if the fields are full - or don't make the button pushable until the fields have something in them.
        // Put up timer and disable navigation buttons. Should there be a cancel?
        self.view.endEditing(true)
        self.manageUserInteractions(false)
        guard let userName = emailTextField.text where userName != "",
            let password = passwordTextField.text where password != "",
            let firstName = firstNameTextField.text where firstName != "",
            let lastName = lastNameTextField.text where lastName != ""
            else { self.presentMissingCredentialError(); return }

        let HTTPBodyDictionary: NSDictionary = ["username": userName, "password": password, "firstName": firstName, "lastName": lastName, "deviceID": ((UIApplication.sharedApplication().delegate as? AppDelegate)?.appDeviceID)!, "platform": "ios"]

        guard let signUpURL = NSURL(string: "http://lava-dev.premonetwork.com:3000/api/v1/signup") else { self.presentUnknownFailure(); return }

        self.sendSignupRequest(signUpURL, HTTPBodyDictionary: HTTPBodyDictionary)

    }

    func sendSignupRequest(signUpURL: NSURL, HTTPBodyDictionary: NSDictionary) {
        if self.currentSignUpTask != nil && self.currentSignUpTask?.state == NSURLSessionTaskState.Running {
            self.currentSignUpTask?.cancel()
            self.currentSignUpTask = nil
        }
        self.signUpResponse = nil

        let signUpRequest = NSMutableURLRequest(URL: signUpURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 30.0)
        signUpRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
        do {
            guard NSJSONSerialization.isValidJSONObject(HTTPBodyDictionary) == true else { throw SignUpError.credentialError }
            let JSONBodyData: NSData = try NSJSONSerialization.dataWithJSONObject(HTTPBodyDictionary, options: NSJSONWritingOptions.init(rawValue: 0))
            signUpRequest.HTTPBody = JSONBodyData
            signUpRequest.HTTPMethod = "POST"
            let signUpTask = self.signUpSession.dataTaskWithRequest(signUpRequest)
            self.currentSignUpTask = signUpTask
            signUpTask.resume()
        } catch {
            self.presentMissingCredentialError()
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
        if self.signUpResponse == nil {
            self.signUpResponse = NSMutableData(data: data)
        } else {
            self.signUpResponse?.appendData(data)
        }
    }

    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if task.state == NSURLSessionTaskState.Canceling { return }
        guard let httpResponse = task.response as? NSHTTPURLResponse else { return }
        do {
            switch httpResponse.statusCode {
            case 200...299:
                guard let response = self.signUpResponse else { throw SignUpError.responseError }
                guard let JSONResponse = try NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary else { throw SignUpError.responseError }
                if (JSONResponse.objectForKey("success") as? NSNumber)!.boolValue == true {
                    self.processSuccessfulSignUp(JSONResponse)
                } else if (JSONResponse.objectForKey("success") as? NSNumber)!.boolValue  == false {
                    self.processFailedSignUp(JSONResponse)
                } else {
                    throw SignUpError.unknownError
                }
            case 400:

                self.presentSignUpError()

                guard let response = self.signUpResponse else { throw SignUpError.responseError }
                guard let JSONResponse = try NSJSONSerialization.JSONObjectWithData(response, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary else { throw SignUpError.responseError }
                print (JSONResponse)

            default:
                throw SignUpError.unknownError
            }
        } catch {
            self.presentUnknownFailure()
        }
    }

    func presentMissingCredentialError() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Login Failed", message: "Your first name, last name, an email address, and a password at least six(6) characters long are required. Please try again or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))

            self.signupActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }

    func presentSignUpError() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Sign Up Failed", message: "The email address was not formatted correctly or the password was shorter than 6 characters. Please try again or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))
            self.signupActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentServerFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Sign Up Failure", message: "Your sign up information was unable to be processed. Please try again or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))

            self.signupActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentAuthorizationFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Authorization Failure", message: "You are currently not authorized to access these services. Please contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))

            self.signupActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }

    }

    func presentUnknownFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Sign Up Failure", message: "An unknown error has occurred preventing sign up. Please check that your internet connection is active or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))

            self.signupActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentCustomFailure(message: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Sign Up Failure", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.manageUserInteractions(true)
            }))

            self.signupActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }


    func processFailedSignUp(payloadDictionary: NSDictionary) {
        do {
            guard let errorDictionary = payloadDictionary.objectForKey("error") as? NSDictionary, let errorCode = errorDictionary.objectForKey("code"), let errorMessage = errorDictionary.objectForKey("message") as? String else { throw SignUpError.unknownError }
            var code:Int? = nil
            if errorCode is String { code = Int(errorCode as! String) } else if errorCode is NSNumber { code = (errorCode as! NSNumber).integerValue }
            guard let resolvedCode = code else { throw SignUpError.unknownError }
            if resolvedCode == 100 || resolvedCode == 102 || resolvedCode == 103 {
                self.presentCustomFailure(errorMessage)
            } else {
                throw SignUpError.unknownError
            }
        } catch {
            self.presentUnknownFailure()
        }
    }

    func processSuccessfulSignUp(payloadDictionary: NSDictionary) {
        guard let jwt = payloadDictionary["payload"]?["jwt"] as? String, let userName = payloadDictionary["payload"]?["member"]?!["email"] as? String, let firstName = payloadDictionary["payload"]?["member"]?!["firstName"] as? String, let lastName = payloadDictionary["payload"]?["member"]?!["lastName"] as? String else { self.presentUnknownFailure(); return }
        NSUserDefaults.standardUserDefaults().setObject(jwt, forKey: "jwt")
        NSUserDefaults.standardUserDefaults().setObject(userName, forKey: "userName")
        NSUserDefaults.standardUserDefaults().setObject(firstName, forKey: "firstName")
        NSUserDefaults.standardUserDefaults().setObject(lastName, forKey: "lastName")
        NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "subscription")

        self.displaySuccessAlert()
    }

    func displaySuccessAlert() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "PREMO Account Created", message: "Your PREMO Account has been created and you have been logged in.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("showSubscribeFromAccount", sender: self)
            }))
            self.signupActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    @IBAction func endEditingInView(sender: AnyObject) {
            self.view.endEditing(true)
    }

    @IBAction func firstNameEditingEnded(sender: AnyObject) {
        lastNameTextField.becomeFirstResponder()
        firstNameTextField.resignFirstResponder()
    }

    @IBAction func lastNameEditingEnded(sender: AnyObject) {
        emailTextField.becomeFirstResponder()
        lastNameTextField.resignFirstResponder()
    }

    @IBAction func emailEditingEnded(sender: AnyObject) {
        passwordTextField.becomeFirstResponder()
        emailTextField.resignFirstResponder()
    }

    func manageUserInteractions(enabled: Bool) {

        if enabled == true {
            self.signupActivityIndicator.stopAnimating()
        } else {
            self.signupActivityIndicator.startAnimating()
        }

        firstNameTextField.userInteractionEnabled = enabled
        lastNameTextField.userInteractionEnabled = enabled
        emailTextField.userInteractionEnabled = enabled
        passwordTextField.userInteractionEnabled = enabled
        signupButton.userInteractionEnabled = enabled
        gotoLoginButton.userInteractionEnabled = enabled
        self.navigationItem.backBarButtonItem?.enabled = enabled
        
    }

}
