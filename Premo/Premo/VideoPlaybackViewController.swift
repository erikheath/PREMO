//
//  VideoPlaybackViewController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/11/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit

class VideoPlaybackViewController: UIViewController {

    weak var playerController: OOOoyalaPlayerViewController? = nil
    weak var player: OOOoyalaPlayer? = nil
    var pCode: String? = nil
    var embedCode: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        if let pCode = self.pCode, let embedCode = self.embedCode {
            let player = OOOoyalaPlayer(pcode: pCode, domain: OOPlayerDomain(string: "https://player.ooyala.com"))
            self.player = player
            player.setEmbedCode(embedCode)
            player.actionAtEnd = OOOoyalaPlayerActionAtEndStop
            player.allowsExternalPlayback = true

            let playerController = OOOoyalaPlayerViewController(player: player, controlType: OOOoyalaPlayerControlType.FullScreen)
            self.playerController = playerController
            playerController.setFullscreen(true)

            self.addChildViewController(playerController)
            self.view.addSubview(playerController.view)
            playerController.view.frame = self.view.bounds
            playerController.player.play()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
