//
//  StyleTemplate.swift
//

import UIKit

class PremoStyleTemplate: NSObject {

    static func navBarFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Light", size: 17)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 17)
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

    static func styleApp() -> Void {
        self.styleNavBar()
    }

}
