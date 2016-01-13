//
//  VideoPlaybackViewController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/11/16.
//  Copyright © 2016 Premo Network. All rights reserved.
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

        var objectType : NSError {
            get {
                return NSError(domain: "LoginError", code: self.rawValue, userInfo: nil)
            }
        }
    }
    
    @IBOutlet weak var playerView: UIView!
    weak var playerController: OOOoyalaPlayerViewController? = nil
    weak var player: OOOoyalaPlayer? = nil
    var pCode: String? = nil
    var embedCode: String? = nil
    var playbackType: PlaybackType? = nil
    lazy var playbackSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)


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
            player.actionAtEnd = OOOoyalaPlayerActionAtEndStop
            player.allowsExternalPlayback = true

            let playerController = OOOoyalaPlayerViewController(player: player, controlType: OOOoyalaPlayerControlType.FullScreen)
            self.playerController = playerController

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

    // MARK: - Embed Token Generator
    func tokenForEmbedCodes(embedCodes: [AnyObject]!, callback: OOEmbedTokenCallback!) {
        do {
            guard let pCode = self.pCode, let embedCode = self.embedCode, let embedCodeURL = NSURL(string: "http://lava-dev.premonetwork.com:3000/api/v1/ooyalaplayertoken/" + pCode + "/" + embedCode) else { throw PlayerError.unknownError }
            let tokenRequest = NSMutableURLRequest(URL: embedCodeURL, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 45.0)
            tokenRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
            tokenRequest.setValue(NSUserDefaults.standardUserDefaults().stringForKey("jwt"), forHTTPHeaderField: "Authorization")
            let tokenRequestTask = self.playbackSession.dataTaskWithRequest(tokenRequest, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
                do {
                    if error != nil || data == nil { throw PlayerError.credentialError }
                    guard let JSONObject = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.init(rawValue: 0)) as? NSDictionary, let success = JSONObject.objectForKey("success") where (success as? NSNumber)!.boolValue == true, let embedTokenURLString = (JSONObject.objectForKey("payload") as? NSDictionary)!.objectForKey("embedTokenUrl") as? String else { throw PlayerError.unknownError }
                    callback(embedTokenURLString)
                } catch { callback("") }
            })

            tokenRequestTask.resume()
        } catch {
            let alert = UIAlertController(title: "Playback Error", message: "There was an error playing the video. Please try again, and if the problem persists, please contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }

}
