//
//  SlideController.swift
//

import UIKit

class SlideController: SWRevealViewController {

    weak var blackStatusBarBackgroundView: UIView? = nil

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

    override func viewDidLoad() {
        super.viewDidLoad()

        let blackstatusbarView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: 22.0))
        blackstatusbarView.backgroundColor = UIColor.blackColor()
        self.blackStatusBarBackgroundView = blackstatusbarView
        self.view.addSubview(blackstatusbarView)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "connectionFailure:", name: AppDelegate.ReachabilityStatus.NotReachable.rawValue, object: nil)
    }

    func connectionFailure(notification: NSNotification) -> Void {
        let alert = UIAlertController(title: "No Internet Connection", message: "After the internet connection is restored, please close and re-start the app.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))

        self.presentViewController(alert, animated: true, completion: nil)
    }

}
