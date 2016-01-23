//
//  WelcomeViewController.swift
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var skipForNowButton: UIButton!

    @IBOutlet weak var tagline: UILabel!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.configureNavigationItemAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureNavigationItemAppearance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var buttonLayer = loginButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0
        buttonLayer.borderColor = UIColor.whiteColor().CGColor
        buttonLayer.borderWidth = 1.5

        buttonLayer = signupButton.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0

        self.tagline.attributedText = self.styledTagline(self.tagline.text!)
        self.signupButton.setAttributedTitle(self.styledButtonText((self.signupButton.titleLabel?.text)!), forState: UIControlState.Normal)
        self.loginButton.setAttributedTitle(self.styledButtonText((self.loginButton.titleLabel?.text)!), forState: UIControlState.Normal)
        self.skipForNowButton.setAttributedTitle(self.styledSkipText((self.skipForNowButton.titleLabel?.text)!), forState: UIControlState.Normal)
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
    }

    override func viewWillAppear(animated: Bool) {
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        super.viewWillAppear(animated)
    }

    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
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

    func buttonFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 14.0)!
//        let newFont = UIFont.systemFontOfSize(20)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 14.0)

    }

    func skipFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 14.0)!
        //        let newFont = UIFont.systemFontOfSize(20)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 14.0)

    }


    func taglineFont() -> UIFont {
        //        let newFont = UIFont(name: "Helvetica-Regular", size: 20)
        let newFont = UIFont.systemFontOfSize(20)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 20)
    }

    func styledTagline(tagline: String) -> NSAttributedString {
        let mutableTagline = NSMutableAttributedString(string: tagline)
        mutableTagline.addAttribute(NSFontAttributeName, value: self.taglineFont(), range: NSMakeRange(0, mutableTagline.length))
        mutableTagline.addAttribute(NSForegroundColorAttributeName, value: UIColor(colorLiteralRed: 221.0/255.0, green: 221.0/255.0, blue: 221.0/255.0, alpha: 1.0), range: NSMakeRange(0, mutableTagline.length))
        mutableTagline.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.5), range: NSMakeRange(0, mutableTagline.length))

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.defaultParagraphStyle())
        paragraphStyle.alignment = .Center
        paragraphStyle.paragraphSpacing = 1
        mutableTagline.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, mutableTagline.length))


        return mutableTagline
    }

    func styledButtonText(buttonText: String) -> NSAttributedString {
        let mutableButtonText = NSMutableAttributedString(string: buttonText)
        mutableButtonText.addAttribute(NSFontAttributeName, value: self.buttonFont(), range: NSMakeRange(0, mutableButtonText.length))
        mutableButtonText.addAttribute(NSForegroundColorAttributeName, value: UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), range: NSMakeRange(0, mutableButtonText.length))
        mutableButtonText.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.5), range: NSMakeRange(0, mutableButtonText.length))

        return mutableButtonText
    }

    func styledSkipText(skipText: String) -> NSAttributedString {
        let mutableSkipText = NSMutableAttributedString(string: skipText)
        mutableSkipText.addAttribute(NSFontAttributeName, value: self.skipFont(), range: NSMakeRange(0, mutableSkipText.length))
        mutableSkipText.addAttribute(NSForegroundColorAttributeName, value: UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), range: NSMakeRange(0, mutableSkipText.length))
        mutableSkipText.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.5), range: NSMakeRange(0, mutableSkipText.length))

        return mutableSkipText
    }



    override func prefersStatusBarHidden() -> Bool {
        return true
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }


    @IBAction func skipLogin(sender: AnyObject) {
        if (self.navigationController as? AppRoutingNavigationController)!.currentNavigationStack == AppRoutingNavigationController.NavigationStack.credentialStack {
            (self.navigationController as? AppRoutingNavigationController)!.transitionToVideoStack(true)
        } else {
            self.performSegueWithIdentifier("unwindFromSubscribe", sender: self)
        }
    }

}
