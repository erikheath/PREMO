//
//  StyleTemplate.swift
//

import UIKit

class PremoStyleTemplate: NSObject {

    // MARK: - UI ELEMENTS

    static func styledTitleLabel(title: String) -> UILabel {

        let mutableItemTitle = NSMutableAttributedString(string: title)
        mutableItemTitle.addAttribute(NSFontAttributeName, value: self.navBarFont(), range: NSMakeRange(0, mutableItemTitle.length))
        mutableItemTitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableItemTitle.length))
        mutableItemTitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: NSMakeRange(0, mutableItemTitle.length))


        let constraintSize = CGSizeMake(CGFloat.max, CGFloat.max)

        let contentFrame = mutableItemTitle.boundingRectWithSize(constraintSize, options:NSStringDrawingOptions.init(rawValue: 0), context: nil)

        let label = UILabel(frame: contentFrame)
        label.attributedText = mutableItemTitle
        return label
    }

    // MARK: - TYPEFACES

    static func navBarFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Light", size: 17)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 17)
    }


    static func callToActionButtonFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 14.0)!
        //        let newFont = UIFont.systemFontOfSize(20)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 14.0)

    }

    static func textButtonFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 14.0)!
        //        let newFont = UIFont.systemFontOfSize(20)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 14.0)
        
    }

    // MARK: - STRING FORMATTING

    static func styledButtonText(buttonText: String) -> NSAttributedString {
        let mutableButtonText = NSMutableAttributedString(string: buttonText)
        mutableButtonText.addAttribute(NSFontAttributeName, value: self.callToActionButtonFont(), range: NSMakeRange(0, mutableButtonText.length))
        mutableButtonText.addAttribute(NSForegroundColorAttributeName, value: UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), range: NSMakeRange(0, mutableButtonText.length))
        mutableButtonText.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.5), range: NSMakeRange(0, mutableButtonText.length))

        return mutableButtonText
    }

    static func styledTextButtonText(buttonText: String) -> NSAttributedString {
        let mutableButtonText = NSMutableAttributedString(string: buttonText)
        mutableButtonText.addAttribute(NSFontAttributeName, value: self.textButtonFont(), range: NSMakeRange(0, mutableButtonText.length))
        mutableButtonText.addAttribute(NSForegroundColorAttributeName, value: UIColor(colorLiteralRed: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), range: NSMakeRange(0, mutableButtonText.length))
        mutableButtonText.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.5), range: NSMakeRange(0, mutableButtonText.length))

        return mutableButtonText
    }

    // MARK: - STYLE ACTIONS

    static func styleApp() -> Void {
        self.styleNavBar()
    }

    static func styleCallToActionButton(button: UIButton) -> Void {

        let buttonLayer = button.layer
        buttonLayer.masksToBounds = true
        buttonLayer.cornerRadius = 5.0

        button.setAttributedTitle(self.styledButtonText((button.titleLabel?.text)!), forState: UIControlState.Normal)

    }

    static func styleTextButton(button: UIButton) -> Void {
        button.setAttributedTitle(self.styledTextButtonText((button.titleLabel?.text)!), forState: UIControlState.Normal)
    }

    static func styleNavBar() -> Void {
        let navbarProxy = UINavigationBar.appearance()
        navbarProxy.barTintColor = UIColor.blackColor()
        navbarProxy.tintColor = UIColor.whiteColor()
        navbarProxy.barStyle = UIBarStyle.Black
        navbarProxy.titleTextAttributes = [NSFontAttributeName: self.navBarFont()]
        navbarProxy.backIndicatorImage = UIImage(named: "back")
        navbarProxy.backIndicatorTransitionMaskImage = UIImage(named: "back")
        navbarProxy.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        navbarProxy.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navbarProxy.shadowImage = UIImage()
    }

    static func styleVisibleNavBar(navbar: UINavigationBar) -> Void {
        navbar.barTintColor = UIColor.blackColor()
        navbar.tintColor = UIColor.whiteColor()
        navbar.barStyle = UIBarStyle.Black
        navbar.titleTextAttributes = [NSFontAttributeName: self.navBarFont()]
        navbar.backIndicatorImage = UIImage(named: "back")
        navbar.backIndicatorTransitionMaskImage = UIImage(named: "back")
        navbar.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        navbar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navbar.shadowImage = UIImage()
        navbar.translucent = false
    }

    static func styleFullScreenNavBar(navbar: UINavigationBar) -> Void {
        navbar.tintColor = UIColor.whiteColor()
        navbar.barStyle = UIBarStyle.Black
        navbar.titleTextAttributes = [NSFontAttributeName: self.navBarFont()]
        navbar.backIndicatorImage = UIImage(named: "back")
        navbar.backIndicatorTransitionMaskImage = UIImage(named: "back")
        navbar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        navbar.shadowImage = UIImage()
        navbar.barTintColor = UIColor.clearColor()
        navbar.translucent = true
        navbar.backgroundColor = UIColor.clearColor()
    }

}
