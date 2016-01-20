//
//  SlideController.swift
//

import UIKit

class SlideController: SWRevealViewController {

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if (self.frontViewController as? AppRoutingNavigationController)?.viewControllers.last is VideoPlaybackViewController {
            return UIInterfaceOrientationMask.Landscape
        } else {
            return UIInterfaceOrientationMask.Portrait
        }
    }

    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }
}
