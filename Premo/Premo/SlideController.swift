//
//  SlideController.swift
//

import UIKit

class SlideController: SWRevealViewController {

    var screenshot: UIView? = nil

    override init!(rearViewController: UIViewController!, frontViewController: UIViewController!) {
        super.init(rearViewController: rearViewController, frontViewController: frontViewController)
        configureController()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureController()
    }

    func configureController() {
        self.toggleAnimationType = .EaseOut
        self.frontViewShadowRadius = 0.0
        self.frontViewShadowOffset = CGSizeMake(-1.0, 0.0)
        self.frontViewShadowOpacity = 1.0
        self.frontViewShadowColor = UIColor(colorLiteralRed: 73/255.0, green: 73/255.0, blue: 73/255.0, alpha: 1.0)
        self.rearViewRevealWidth = -76.0
    }

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
