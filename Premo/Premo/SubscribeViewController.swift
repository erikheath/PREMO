//
//  SubscribeViewController.swift
//  Premo
//
//  Created by ERIKHEATH A THOMAS on 1/1/16.
//  Copyright © 2016 Premo Network. All rights reserved.
//

import UIKit

class SubscribeViewController: UIViewController {

    @IBOutlet weak var subscribeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        let buttonLayer = subscribeButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func subscribe(sender: AnyObject) {
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
