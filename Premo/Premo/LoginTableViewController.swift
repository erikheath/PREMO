//
//  LoginTableViewController.swift
//

import UIKit
import FBSDKLoginKit

class LoginTableViewController: UITableViewController, NSURLSessionDelegate, NSURLSessionDataDelegate {

    // MARK: - PROPERTIES

    // MARK: - Errors
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


    // MARK: System Interaction

    lazy var loginSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)

    weak var currentLoginTask: NSURLSessionDataTask? = nil
    var loginResponse: NSMutableData? = nil

    /**
     The url path used for all premo facebook login requests
     */
    let facebookLoginPath = "/api/v1/connect/facebook"

    /**
     The url path used for all premo login requests
     */
    let PREMOLoginPath = "/api/v1/login"


    // MARK: User Interface

    @IBOutlet weak var emailTextField: UITextField!

    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var loginButton: UIButton!

    @IBOutlet weak var forgotPasswordButton: UIButton!

    @IBOutlet weak var loginActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var facebookLoginButton: UIButton!

    @IBOutlet weak var needAnAccountButton: UIButton!

    @IBOutlet weak var skipLoginButton: UIButton!


    // MARK: - OBJECT LIFECYCLE

    // MARK: Setup & Teardown
    override func viewDidLoad() {
        super.viewDidLoad()

        PremoStyleTemplate.styleCallToActionButton(self.loginButton)
        PremoStyleTemplate.styleCallToActionButton(self.facebookLoginButton)
        PremoStyleTemplate.styleTextButton(self.forgotPasswordButton)
        PremoStyleTemplate.styleTextButton(self.needAnAccountButton)
        PremoStyleTemplate.styleTextButton(self.skipLoginButton)
    }

    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
    }

    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = ""
            self.navigationItem.hidesBackButton = false
            let titleViewImageView = UIImageView(image: UIImage(named: "PREMO_titlebar"))
            titleViewImageView.contentMode = .ScaleAspectFit
            self.navigationItem.titleView = titleViewImageView
        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = false
            PremoStyleTemplate.styleVisibleNavBar(navbarController.navigationBar)

        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    // MARK: System Interaction

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showCreateAccountFromLogin" && self.navigationController?.childViewControllers.contains({ (controller: UIViewController) -> Bool in
            return controller.dynamicType == CreateAccountTableViewController.self
        }) == true {
            // Perform an unwind instead
            self.performSegueWithIdentifier("unwindToCreateAccountFromLogin", sender: self)
            return false
        }

        return true
    }

    @IBAction func unwindToLoginFromCreateAccount(sender: UIStoryboardSegue) {

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
            do {
                let HTTPBodyDictionary: NSDictionary = ["userID": FBSDKAccessToken.currentAccessToken().userID, "accessToken": FBSDKAccessToken.currentAccessToken().tokenString, "deviceID": AppDelegate.appDeviceID, "platform": "ios"]
                let loginRequest = try NSMutableURLRequest.PREMOURLRequest(self.facebookLoginPath, method: NSMutableURLRequest.PREMORequestMethod.POST, HTTPBody: HTTPBodyDictionary, authorizationRequired: true)
                self.sendLoginRequest(loginRequest)
            } catch {
                self.presentLoginError()
                return
            }
        }

        self.manageUserInteractions(false)
        if FBSDKAccessToken.currentAccessToken() != nil {
            processFacebookLogin()
            return
        }

        let loginManager = FBSDKLoginManager()
        loginManager.logInWithReadPermissions(["public_profile", "email"], fromViewController: self) { (result:FBSDKLoginManagerLoginResult!, error: NSError!) -> Void in
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

        do {
            let HTTPBodyDictionary: NSDictionary = ["username": userName, "password": password, "deviceID": AppDelegate.appDeviceID, "platform": "ios"]

            let loginRequest = try NSMutableURLRequest.PREMOURLRequest(self.PREMOLoginPath, method: NSMutableURLRequest.PREMORequestMethod.POST, HTTPBody: HTTPBodyDictionary, authorizationRequired: false)
            self.sendLoginRequest(loginRequest)
        } catch {
            self.presentLoginError()
            return
        }

    }

    @IBAction func showForgotPassword(sender: AnyObject) {
        guard let supportSite = Account.premoForgotPasswordSite else { return }
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

    // MARK: - LOGIN PROCESSING

    func sendLoginRequest(loginRequest: NSMutableURLRequest) {
        let lock = NSLock()
        lock.lock()
        if self.currentLoginTask != nil && self.currentLoginTask?.state == NSURLSessionTaskState.Running {
            self.currentLoginTask?.cancel()
            self.currentLoginTask = nil
        }

        self.loginResponse = nil

        let loginTask = self.loginSession.dataTaskWithRequest(loginRequest)
        self.currentLoginTask = loginTask
        loginTask.resume()

        defer { lock.unlock() }

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
        do {
            try Account.processAccountPayload(payloadDictionary)
            self.presentSuccessAlert()

        } catch Account.AccountError.invalidMemberFormat {
            self.presentCustomFailure("There was a problem with the member information returned from the PREMO service. Please try logging in again or contact PREMO customer support for assistance.")
        } catch Account.AccountError.invalidSubscriptionFormat {
            self.presentCustomFailure("There was a problem with the subscription information returned from the PREMO service. Please try logging in again or contact PREMO customer support for assistance.")
        } catch {
            self.presentCustomFailure("There as a problem with the information returned from the PREMO sercice. Please try logging in again or contact PREMO customer support for assistance.")
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

    func presentSuccessAlert() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "You Are Now Logged In", message: "You have successfully logged into your PREMO account.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                guard let appRouter = self.navigationController as? AppRoutingNavigationController else { return } // There is some error to handle here
                switch appRouter.currentNavigationStack {
                case .accountStack:
                    if Account.subscribed == true {
                    self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
                    } else {
                        self.performSegueWithIdentifier("showSubscribeFromLogin", sender: self)
                    }
                case .credentialStack:
                    if Account.subscribed == true {
                        appRouter.transitionToVideoStack(true)
                    } else {
                        self.performSegueWithIdentifier("showSubscribeFromLogin", sender: self)
                    }
                case .videoStack:
                    if Account.subscribed == true {
                        self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
                    } else {
                        self.performSegueWithIdentifier("showSubscribeFromLogin", sender: self)
                    }
                }
            }))

            self.loginActivityIndicator.stopAnimating()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }


}
