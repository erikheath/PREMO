//
//  VideoPlaybackViewController.swift
//

import UIKit

class VideoPlaybackViewController: UIViewController, OOEmbedTokenGenerator {

    enum PlaybackType: Int {
        case Trailer
        case Feature
    }

    enum PlayerError: Int, ErrorType {
        case unknownError = 5000
        case credentialError = 5001
        case responseError = 5002
        case sourceError = 5003
        case catalogError = 5004
        case invalidJSONFormatError = 5005
        case missingPayloadError = 5006

        var objectType : NSError {
            get {
                return NSError(domain: "LoginError", code: self.rawValue, userInfo: nil)
            }
        }
    }
    
    @IBOutlet weak var playerView: UIView!
    weak var playerController: OOOoyalaPlayerViewController? = nil
    var player: OOOoyalaPlayer? = nil
    var pCode: String? = nil
    var embedCode: String? = nil
    var playbackType: PlaybackType? = nil
    lazy var playbackSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let pCode = self.pCode, let embedCode = self.embedCode, let playback = self.playbackType {
            let player:OOOoyalaPlayer
            if playback == PlaybackType.Trailer {
                player = OOOoyalaPlayer(pcode: pCode, domain: OOPlayerDomain(string: "https://player.ooyala.com"))
            } else {
                player = OOOoyalaPlayer(pcode: pCode, domain: OOPlayerDomain(string: "https://player.ooyala.com"), embedTokenGenerator: self)
            }

            self.player = player
            player.setEmbedCode(embedCode)
            player.actionAtEnd = OOOoyalaPlayerActionAtEndReset
            player.allowsExternalPlayback = true


            let playerController = OOOoyalaPlayerViewController(player: player, controlType: OOOoyalaPlayerControlType.FullScreen)
            self.playerController = playerController
            self.playerController?.setFullscreen(true)

            NSNotificationCenter.defaultCenter().addObserver(self, selector: "fullscreenExit:", name: OOOoyalaPlayerViewControllerFullscreenExit, object: self.playerController)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerNotificationObserver", name: OOOoyalaPlayerErrorNotification, object: self.player)
//            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerNotificationObserver:", name: nil, object: self.playerController)

            self.addChildViewController(playerController)
            self.playerView.addSubview(playerController.view)
            playerController.view.frame = self.playerView.bounds
            playerController.player.play()
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }


//    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
//        return UIInterfaceOrientation.LandscapeLeft
//    }

    //MARK: Process Observations

    // MARK: Process Notifications
    func playerNotificationObserver(notification: NSNotification) {
        print(notification)
    }

    func fullscreenExit(notification: NSNotification) {
        self.performSegueWithIdentifier("unwindFromVideoPlayback", sender: self)
    }


    // MARK: - Embed Token Generator
    func tokenForEmbedCodes(embedCodes: [AnyObject]!, callback: OOEmbedTokenCallback!) {
        do {
            guard let pCode = self.pCode, let embedCode = self.embedCode else { throw PlayerError.unknownError }

            let tokenRequest = try NSMutableURLRequest.PREMOURLRequest("/api/v1/ooyalaplayertoken/" + pCode + "/" + embedCode, method: NSMutableURLRequest.PREMORequestMethod.GET, HTTPBody: nil, authorizationRequired: true)

            let tokenRequestTask = self.playbackSession.dataTaskWithRequest(tokenRequest, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in

                guard error == nil else {
                    self.presentUnknownFailure()
                    return
                }

                guard let httpResponse = response as? NSHTTPURLResponse else {
                    self.presentServerFailure()
                    return
                }

                guard let responseData = data else {
                    self.presentServerFailure()
                    return
                }

                switch httpResponse.statusCode {
                case 200...299:
                    self.processEmbedTokenResponse(responseData, callback: callback)

                case 400:
                    self.presentAuthorizationFailure()

                case 401:
                    self.presentAuthorizationFailure()

                case 404, 500:
                    self.presentServerFailure()

                default:
                    self.presentUnknownFailure()
                    
                }
            })

            tokenRequestTask.resume()
        } catch {
            self.presentPlaybackError()
        }
    }

    func processEmbedTokenResponse(responseData: NSData, callback: OOEmbedTokenCallback!) -> Void {
        do {
            guard let JSONObject = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary else { throw PlayerError.invalidJSONFormatError }

            guard let success = JSONObject.objectForKey("success") where (success as? NSNumber)!.boolValue == true else { throw PlayerError.responseError }

            try Account.processAccountPayload(JSONObject)

            guard let embedTokenURLString = (JSONObject.objectForKey("payload") as? NSDictionary)!.objectForKey("embedTokenUrl") as? String else { throw PlayerError.missingPayloadError }

            callback(embedTokenURLString)
        }
        catch is PlayerError { self.presentServerFailure() }
        catch is Account.AccountError { self.presentAuthorizationFailure() }
        catch { self.presentUnknownFailure() }

    }

    func presentAudioOnlyPlayback() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Low Bandwidth Playback", message: "The video will continue to playback as an audio only stream until your connection speed improves.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentServerFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Playback Failure", message: "An unexpected response was received while authenticating your account. Please login again or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("unwindFromVideoPlayback", sender: self)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentPlaybackError() -> Void {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
        let alert = UIAlertController(title: "Playback Error", message: "There was an error playing the video. Please try again, and if the problem persists, please contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("unwindFromVideoPlayback", sender: self)
            }))

        self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentAuthorizationFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let alert = UIAlertController(title: "Authorization Failure", message: "You are currently not authorized to access these services. Please login to your account or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Login", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                guard var controllers = self.navigationController?.viewControllers, let loginController = self.storyboard?.instantiateViewControllerWithIdentifier("WelcomeViewController") else { self.performSegueWithIdentifier("unwindFromVideoPlayback", sender: self); return }
                controllers.popLast()
                controllers.append(loginController)
                self.navigationController?.setViewControllers(controllers, animated: true)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("unwindFromVideoPlayback", sender: self)
            }))

            Account.clearAccountSettings()
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentUnknownFailure() {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Playback Failure", message: "An unknown error has occurred preventing playback. Please check that your internet connection is active or contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("unwindFromVideoPlayback", sender: self)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    func presentCustomFailure(message: String) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in

            let alert = UIAlertController(title: "Playback Failure", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("unwindFromVideoPlayback", sender: self)
            }))

            self.presentViewController(alert, animated: true, completion: nil)
        }
    }


}
