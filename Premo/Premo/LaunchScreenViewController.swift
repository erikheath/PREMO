//
//  LaunchScreenViewController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/27/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit

class LaunchScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        (self.revealViewController() as? SlideController)!.blackStatusBarBackgroundView?.backgroundColor = UIColor.clearColor()

        super.viewWillAppear(animated)
    }

    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "  ", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = ""
            self.navigationItem.hidesBackButton = true
        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = false
            PremoStyleTemplate.styleFullScreenNavBar(navbarController.navigationBar)
        }
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
