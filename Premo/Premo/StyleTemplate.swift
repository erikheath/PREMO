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
    }

    static func styleApp() -> Void {
        self.styleNavBar()
    }

}
