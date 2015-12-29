//
//  FeatureTableViewController.swift
//

import UIKit
import CoreData

class FeatureTableViewController: UITableViewController {

    var contentItem: ContentItem? = nil
    var previewMask: UIImage? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(animated: Bool) {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        guard let navbarController = self.parentViewController as? UINavigationController else { return }
        navbarController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "back")
        navbarController.navigationBar.backIndicatorImage = UIImage(named: "back")
        self.navigationItem.title = contentItem?.contentDetailDisplayTitle

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0, 1:
            return 1
        case 2:
            return  5
        default:
            return 0
        }

    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: UITableViewCell
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCellWithIdentifier("DetailPosterCell", forIndexPath: indexPath)
            self.configureDetailPosterCell(cell, indexPath: indexPath)
            break
        case 1:
            cell = tableView.dequeueReusableCellWithIdentifier("ControllerCell", forIndexPath: indexPath)
            guard let controllerCell = cell as? ControllerTableViewCell else { break }
            self.configureControllerCell(controllerCell, indexPath: indexPath)
            break
        case 2:
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCellWithIdentifier("FeatureCell", forIndexPath: indexPath)
            } else if indexPath.row == 1{
                cell = tableView.dequeueReusableCellWithIdentifier("SynopsisCell", forIndexPath: indexPath)
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier("CreditedCell", forIndexPath: indexPath)
            }
            self.configureCreditsCell(cell, indexPath: indexPath)
            break
        default:
            cell = tableView.dequeueReusableCellWithIdentifier("CreditsCell", forIndexPath: indexPath)
            break
        }

        return cell
    }

    func configureDetailPosterCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        guard let posterCell = cell as? DetailPosterTableViewCell, let posterImageData = self.contentItem?.artwork?.artwork269x152 else {
            return
        }
        if self.previewMask == nil {
            let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
            let gradientFilter = CIFilter(name: "CISmoothLinearGradient")
            gradientFilter?.setDefaults()
            gradientFilter?.setValue(CIColor(color: UIColor.blackColor()), forKey: "inputColor1")
            gradientFilter?.setValue(CIColor(color: UIColor.clearColor()), forKey: "inputColor0")
            gradientFilter?.setValue(CIVector(x: 0, y: 50), forKey: "inputPoint1")
            guard let outputImageRecipe = gradientFilter?.outputImage else { return }
            let outputImage = context.createCGImage(outputImageRecipe, fromRect: cell.bounds)
            self.previewMask = UIImage(CGImage: outputImage)
        }
        let newImageView = UIImageView(image: self.previewMask)
        let posterImage = UIImage(data: posterImageData)
        posterCell.detailPosterImageView.image = posterImage
        posterCell.detailPosterImageView.maskView = newImageView
    }

    func configureControllerCell(cell: ControllerTableViewCell, indexPath: NSIndexPath) {
        cell.delegate = self
        cell.shareFeatureButton.setAttributedTitle(self.attributedControllerButtonTitle("Share"), forState: .Normal)
        cell.playTrailerButton.setAttributedTitle(self.attributedControllerButtonTitle("Trailer"), forState: .Normal)
    }

    func configureCreditsCell(cell: UITableViewCell, indexPath: NSIndexPath) {

        var header: NSAttributedString? = nil
        var content: NSAttributedString? = nil

        switch indexPath.row {
        case 0:
            if let description = contentItem?.contentDetailDisplayTitle {
                header = self.attributedFeatureTitle(description)
                content = self.attributedFeatureDetails(formatFeatureDetailsList())
            }
        case 1:
            if let description = contentItem?.contentSynopsis {
                header = self.attributedCreditHeader("Synopsis")
                content = self.attributedCreditContent(description)
            }

        case 2:
            if let description = contentItem?.actors where description.count > 0 {
                header = self.attributedCreditHeader("Starring")
                content = self.attributedCreditContent(self.formatCreditedNameList(description))
            }

        case 3:
            if let description = contentItem?.directors where description.count > 0 {
                header = self.attributedCreditHeader("Director")
                content = self.attributedCreditContent(self.formatCreditedNameList(description))
            }

        case 4:
            if let description = contentItem?.producers where description.count > 0 {
                header = self.attributedCreditHeader("Producers")
                content = self.attributedCreditContent(self.formatCreditedNameList(description))
            }

        default:
            break
        }

        cell.textLabel?.attributedText = header
        cell.detailTextLabel?.attributedText = content
//        cell.header.attributedText = header
//        cell.content.attributedText = content
    }

    func formatCreditedNameList(description: NSOrderedSet) -> String {
        var creditedNames: String? = nil
        for object in description where object is NSManagedObject {
            guard let credit = object as? NSManagedObject else { continue }
            if creditedNames == nil {
                creditedNames = credit.valueForKey("creditedName") as? String
            } else {
                guard let name = credit.valueForKey("creditedName") as? String else { continue }
                creditedNames = creditedNames! + " and " + name
            }
        }

        return creditedNames ?? ""
    }

    func formatFeatureDetailsList() -> String {
        var featureDetails: String = ""

        func detailString(inputString: String?, featureDetails: String) -> String {
            guard let inputString = inputString else { return featureDetails }
            if featureDetails == "" {
                return inputString
            } else {
                return featureDetails + "    |    " + inputString
            }
        }

        featureDetails = detailString(self.contentItem?.contentReleaseYear, featureDetails: featureDetails)
        featureDetails = detailString(self.contentItem?.contentRating, featureDetails: featureDetails)
        if let seconds = self.contentItem?.contentRuntime {
            let minuteString = String(seconds.integerValue / 60) + "MIN"
            featureDetails = detailString(minuteString, featureDetails: featureDetails)
        }

        return featureDetails ?? ""
    }



    func attributedCreditHeader(inputString: String) -> NSAttributedString {
        let creditHeader = (inputString as NSString).uppercaseString
        let mutableCreditHeader = NSMutableAttributedString(string: creditHeader)
        mutableCreditHeader.addAttribute(NSFontAttributeName, value: self.creditHeaderFont(), range: NSMakeRange(0, mutableCreditHeader.length))
        return mutableCreditHeader
    }

    func attributedCreditContent(inputString: String) -> NSAttributedString {
        let mutableCreditContent = NSMutableAttributedString(string: inputString)
        mutableCreditContent.addAttribute(NSFontAttributeName, value: self.creditContentFont(), range: NSMakeRange(0, mutableCreditContent.length))
        return mutableCreditContent
    }

    func attributedFeatureTitle(inputString: String) -> NSAttributedString {
        let featureTitle = (inputString as NSString).uppercaseString
        let mutableFeatureTitle = NSMutableAttributedString(string: featureTitle)
        mutableFeatureTitle.addAttribute(NSFontAttributeName, value: self.featureTitleFont(), range: NSMakeRange(0, mutableFeatureTitle.length))
        mutableFeatureTitle.addAttribute(NSBaselineOffsetAttributeName, value: NSNumber(float: 2.0), range: NSMakeRange(0, mutableFeatureTitle.length))

        return mutableFeatureTitle
    }

    func attributedFeatureDetails(inputString: String) -> NSAttributedString {
        let mutableFeatureSubtitle = NSMutableAttributedString(string: inputString)
        mutableFeatureSubtitle.addAttribute(NSFontAttributeName, value: self.featureDetailsFont(), range: NSMakeRange(0, mutableFeatureSubtitle.length))

        return mutableFeatureSubtitle
    }

    func attributedControllerButtonTitle(inputString: String) -> NSAttributedString {
        let buttonTitle = (inputString as NSString).uppercaseString
        let mutableButtonTitle = NSMutableAttributedString(string: buttonTitle)
        mutableButtonTitle.addAttribute(NSFontAttributeName, value: self.buttonTitleFont(), range: NSMakeRange(0, mutableButtonTitle.length))
        mutableButtonTitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: NSMakeRange(0, mutableButtonTitle.length))
        return mutableButtonTitle
    }

    func buttonTitleFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 12.0)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 12.0)
    }

    func creditHeaderFont() -> UIFont {
        let newFont = UIFont(name: "Helvetica-Light", size: 11)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 11)
    }

    func creditContentFont() -> UIFont {
        let newFont = UIFont(name: "Helvetica-Light", size: 15)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 15)
    }

    func featureTitleFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Light", size: 18.0)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 18.0)
    }

    func featureDetailsFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 11.0)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 11)
    }



    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Returns a view loaded from a xib for the header.
        var categoryView: UIView? = nil
        switch section {
        case 1, 2:
            categoryView = NSBundle.mainBundle().loadNibNamed("FeatureSectionDivider", owner: self, options: nil)[0] as? UIView
        default:
            break
        }
        return categoryView
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var height: CGFloat = 0.0
        switch section {
        case 1, 2:
            height = 1.0
        default:
            break
        }

        return height
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var height: CGFloat = 0.0
        switch indexPath.section {
        case 0:
            height = 152.0
        case 1:
            height = 54.0
        case 2:
            switch indexPath.row {
            case 0:
                height = 66.0

            case 1:
                let constraintWidth = tableView.bounds.size.width - tableView.layoutMargins.left - tableView.layoutMargins.right
                let constraintSize = CGSizeMake(constraintWidth, CGFloat.max)
                if let description = contentItem?.contentSynopsis {
                    let content = self.attributedCreditContent(description)
                    let contentHeight = content.boundingRectWithSize(constraintSize, options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil).height
                    height = ceil(contentHeight) + 18.0
                }

            default:
                height = 50.0
                break
            }

        default:
            break
        }
        return height
    }


}
