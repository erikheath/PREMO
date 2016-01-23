//
//  FeatureTableViewController.swift
//

import UIKit
import CoreData


class FeatureTableViewController: UITableViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate {

    enum PlaybackError: Int, ErrorType {
        case unknownError = 5000
        case credentialError = 5001
        case responseError = 5002
        case sourceError = 5003
        case catalogError = 5004

        var objectType : NSError {
            get {
                return NSError(domain: "LoginError", code: self.rawValue, userInfo: nil)
            }
        }
    }


    var contentItem: ContentItem? = nil

    lazy var playbackSession: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: nil, delegateQueue: nil)

    lazy var featurePcode: String? =  {
        let contentSource = self.contentItem?.contentSource
        guard let sources = self.contentItem?.categoryMember?.appConfig?.catalogSources as? Set<Catalog> else { return nil }
        var pCode: String? = nil
        for catalog in sources {
            if catalog.catalogSource == contentSource {
                pCode = catalog.catalogPcode
                break
            }
        }
        return pCode
    }()

    lazy var featureEmbedCode: String? = { self.contentItem?.contentSourceID }()

    lazy var trailerPcode: String? = {
        let contentSource = self.contentItem?.trailers?.trailerSource
        guard let sources = self.contentItem?.categoryMember?.appConfig?.catalogSources as? Set<Catalog> else { return nil }
        var pCode: String? = nil
        for catalog in sources {
            if catalog.catalogSource == contentSource {
                pCode = catalog.catalogPcode
                break
            }
        }
        return pCode
    }()

    lazy var trailerEmbedCode: String? = { self.contentItem?.trailers?.trailerSourceID }()

    // MARK: - OBJECT LIFECYCYLE
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.configureNavigationItemAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureNavigationItemAppearance()
    }

    override init(style: UITableViewStyle) {
        super.init(style: style)
        self.configureNavigationItemAppearance()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.navigationItem.hidesBackButton = false
            self.navigationItem.title = contentItem?.contentDetailDisplayTitle
            if let _ = self.navigationItem.title {
            self.navigationItem.titleView = PremoStyleTemplate.styledTitleLabel(self.navigationItem.title!)
            }
        }
        
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = false
            PremoStyleTemplate.styleVisibleNavBar(navbarController.navigationBar)

        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationBarAppearance()
        self.configureNavigationItemAppearance()
        guard let contentItem = self.contentItem else { return }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processCoreDataNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: contentItem.managedObjectContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processCoreDataNotification:", name: NSManagedObjectContextDidSaveNotification, object: contentItem.managedObjectContext)
    }

    override func viewWillAppear(animated: Bool) {
        self.configureNavigationBarAppearance()
        self.configureNavigationItemAppearance()
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func shouldAutomaticallyForwardRotationMethods() -> Bool {
        return true
    }

    // MARK: - Navigation

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        switch identifier {
        case "showTrailer":
            guard let _ = self.trailerEmbedCode, let _ = self.trailerPcode else {
                let alert = UIAlertController(title: "Playback Error", message: "There was an error playing the video. Please try again, and if the problem persists, please contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

                self.presentViewController(alert, animated: true, completion: nil)
                return false
            }

        case "showFeature":
            guard let _ = self.featureEmbedCode, let _ = self.featurePcode else {
                let alert = UIAlertController(title: "Playback Error", message: "There was an error playing the video. Please try again, and if the problem persists, please contact PREMO support for assistance.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))

                self.presentViewController(alert, animated: true, completion: nil)
                return false
            }

        default:
            break
        }

        return true
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "showTrailer":
            guard let embedCode = self.trailerEmbedCode, let pCode = self.trailerPcode else { return }
            (segue.destinationViewController as? VideoPlaybackViewController)?.pCode = pCode
            (segue.destinationViewController as? VideoPlaybackViewController)?.embedCode = embedCode
            (segue.destinationViewController as? VideoPlaybackViewController)?.playbackType = VideoPlaybackViewController.PlaybackType.Trailer

        case "showFeature":
            guard let embedCode = self.featureEmbedCode, let pCode = self.featurePcode else { return }
            (segue.destinationViewController as? VideoPlaybackViewController)?.pCode = pCode
            (segue.destinationViewController as? VideoPlaybackViewController)?.embedCode = embedCode
            (segue.destinationViewController as? VideoPlaybackViewController)?.playbackType = VideoPlaybackViewController.PlaybackType.Feature
        default:
            break
        }
    }

    @IBAction func updateCredentials(sender: AnyObject) {
        if Account.loggedIn == true {
            let alert = UIAlertController(title: "Subscription Required", message: "To access full-length features, please subscribe to PREMO. Watch films, comedies, originals and more for $4.99/month, after a FREE 30-day trial.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Subscribe Now", style: .Default, handler: { (action: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("ShowSubscribeFromFeature", sender: self)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)

        } else {
            let alert = UIAlertController(title: "Subscription Required", message: "To access full-length features, please subscribe to PREMO. Watch films, comedies, originals and more for $4.99/month, after a FREE 30-day trial.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Subscribe Now", style: .Default, handler: { (action: UIAlertAction) -> Void in
                self.performSegueWithIdentifier("ShowWelcomeFromFeature", sender: self)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)

        }
    }

    @IBAction func unwindFromSubscribe(unwindSegue: UIStoryboardSegue) {

    }

    @IBAction func unwindFromVideoPlayback(unwindSegue: UIStoryboardSegue) {

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
        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        let gradientFilter = CIFilter(name: "CISmoothLinearGradient")
        gradientFilter?.setDefaults()
        gradientFilter?.setValue(CIColor(color: UIColor.clearColor()), forKey: "inputColor1")
        gradientFilter?.setValue(CIColor(color: UIColor.blackColor()), forKey: "inputColor0")
        gradientFilter?.setValue(CIVector(x: 0, y: -20), forKey: "inputPoint0")
        gradientFilter?.setValue(CIVector(x: 0, y: 220), forKey: "inputPoint1")
        guard let gradientImageRecipe = gradientFilter?.outputImage else { return }

        guard let posterCoreImage = CIImage(data: posterImageData) else { return }
        let compositeFilter = CIFilter(name: "CISourceOverCompositing")
        compositeFilter?.setDefaults()
        compositeFilter?.setValue(gradientImageRecipe, forKey: "inputImage")
        compositeFilter?.setValue(posterCoreImage, forKey: "inputBackgroundImage")
        guard let outputImageRecipie = compositeFilter?.outputImage else { return }

        guard let targetImageSize = UIImage(data: posterImageData)?.size else { return }
        let outputImage = context.createCGImage(outputImageRecipie, fromRect: CGRectMake(0, 0, targetImageSize.width, targetImageSize.height))
        let posterImage: UIImage? = UIImage(CGImage: outputImage)
        guard let _ = posterImage else { return }
        posterCell.subscribeToPlayButton.setBackgroundImage(posterImage, forState: UIControlState.Normal)
        posterCell.readyToPlayButton.setBackgroundImage(posterImage, forState: UIControlState.Normal)
        if let subscriptionValidUntilDate = NSUserDefaults.standardUserDefaults().objectForKey("subscriptionValidUntilDate") as? NSDate where subscriptionValidUntilDate.compare(NSDate()) == NSComparisonResult.OrderedDescending  {
            posterCell.subscribeToPlayButton.hidden = true
            posterCell.readyToPlayButton.hidden = false
        }
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
            if let description = contentItem?.contentDetailDisplayTitle, cell = cell as? FeatureDetailTableViewCell {
                cell.featureTitle.attributedText = self.attributedFeatureTitle(description)
                cell.featureDetailsSubtitle.attributedText = self.attributedFeatureDetails(formatFeatureDetailsList())

            }
        case 1:
            if let description = contentItem?.contentSynopsis {
                header = self.attributedCreditHeader("Synopsis")
                content = self.attributedCreditContent(description)
                cell.textLabel?.attributedText = header
                cell.detailTextLabel?.attributedText = content
            }

        case 2:
            if let description = contentItem?.actors where description.count > 0 {
                header = self.attributedCreditHeader("Starring")
                content = self.attributedCreditContent(self.formatCreditedNameList(description, limit: 2))
                cell.textLabel?.attributedText = header
                cell.detailTextLabel?.attributedText = content
            }

        case 3:
            if let description = contentItem?.directors where description.count > 0 {
                header = self.attributedCreditHeader("Director")
                content = self.attributedCreditContent(self.formatCreditedNameList(description, limit: 2))
                cell.textLabel?.attributedText = header
                cell.detailTextLabel?.attributedText = content
            }

        case 4:
            if let description = contentItem?.producers where description.count > 0 {
                header = self.attributedCreditHeader("Producers")
                content = self.attributedCreditContent(self.formatCreditedNameList(description, limit: 2))
                cell.textLabel?.attributedText = header
                cell.detailTextLabel?.attributedText = content
            }

        default:
            break
        }

    }

    func formatCreditedNameList(description: NSOrderedSet, limit: Int) -> String {
        var count = 0
        var creditedNames: String? = nil
        for object in description where object is NSManagedObject {
            guard let credit = object as? NSManagedObject else { continue }
            if creditedNames == nil {
                creditedNames = credit.valueForKey("creditedName") as? String
            } else {
                guard let name = credit.valueForKey("creditedName") as? String else { continue }
                creditedNames = creditedNames! + " and " + name
            }
            count = count + 1
            if count == limit { break }
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
                return featureDetails + "   |   " + inputString
            }
        }

        featureDetails = detailString(self.contentItem?.contentReleaseYear, featureDetails: featureDetails)
        featureDetails = detailString(self.contentItem?.contentRating, featureDetails: featureDetails)
        if let seconds = self.contentItem?.contentRuntime {
            let minuteString = String(seconds.integerValue / 60) + " Min"
            featureDetails = detailString(minuteString, featureDetails: featureDetails)
        }
        guard let genreName = (contentItem?.genres?.firstObject as? Genre)!.genreName  else { return featureDetails ?? "" }
        featureDetails = detailString((genreName as NSString).uppercaseString , featureDetails: featureDetails)

        guard let cc = contentItem?.contentCaptionsIncluded else { return featureDetails ?? "" }
        if cc == true { featureDetails = detailString("CC", featureDetails: featureDetails) }

        return featureDetails ?? ""
    }



    func attributedCreditHeader(inputString: String) -> NSAttributedString {
        let creditHeader = (inputString as NSString).uppercaseString
        let mutableCreditHeader = NSMutableAttributedString(string: creditHeader)
        mutableCreditHeader.addAttribute(NSFontAttributeName, value: self.creditHeaderFont(), range: NSMakeRange(0, mutableCreditHeader.length))
        mutableCreditHeader.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableCreditHeader.length))
        return mutableCreditHeader
    }

    func attributedCreditContent(inputString: String) -> NSAttributedString {
        let mutableCreditContent = NSMutableAttributedString(string: inputString)
        mutableCreditContent.addAttribute(NSFontAttributeName, value: self.creditContentFont(), range: NSMakeRange(0, mutableCreditContent.length))
        mutableCreditContent.addAttribute(NSKernAttributeName, value: NSNumber(float: 0.55), range: NSMakeRange(0, mutableCreditContent.length))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.defaultParagraphStyle())
        paragraphStyle.lineHeightMultiple = 1.20
        mutableCreditContent.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, mutableCreditContent.length))
        return mutableCreditContent
    }

    func attributedFeatureTitle(inputString: String) -> NSAttributedString {
        let featureTitle = (inputString as NSString).uppercaseString
        let mutableFeatureTitle = NSMutableAttributedString(string: featureTitle)
        mutableFeatureTitle.addAttribute(NSFontAttributeName, value: self.featureTitleFont(), range: NSMakeRange(0, mutableFeatureTitle.length))
        mutableFeatureTitle.addAttribute(NSBaselineOffsetAttributeName, value: NSNumber(float: 2.0), range: NSMakeRange(0, mutableFeatureTitle.length))
        mutableFeatureTitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableFeatureTitle.length))

        return mutableFeatureTitle
    }

    func attributedFeatureDetails(inputString: String) -> NSAttributedString {
        let mutableFeatureSubtitle = NSMutableAttributedString(string: inputString)
        mutableFeatureSubtitle.addAttribute(NSFontAttributeName, value: self.featureDetailsFont(), range: NSMakeRange(0, mutableFeatureSubtitle.length))
        mutableFeatureSubtitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableFeatureSubtitle.length))

        return mutableFeatureSubtitle
    }

    func attributedControllerButtonTitle(inputString: String) -> NSAttributedString {
        let buttonTitle = (inputString as NSString).uppercaseString
        let mutableButtonTitle = NSMutableAttributedString(string: buttonTitle)
        mutableButtonTitle.addAttribute(NSFontAttributeName, value: self.buttonTitleFont(), range: NSMakeRange(0, mutableButtonTitle.length))
        mutableButtonTitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: NSMakeRange(0, mutableButtonTitle.length))
        mutableButtonTitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableButtonTitle.length))
        return mutableButtonTitle
    }

    func buttonTitleFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 12.0)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 12.0)
    }

    func creditHeaderFont() -> UIFont {
        let newFont = UIFont(name: "Helvetica-Light", size: 11)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 11)
    }

    func creditContentFont() -> UIFont {
        let newFont = UIFont(name: "Helvetica-Light", size: 14)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 14)
    }

    func featureTitleFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Light", size: 18.0)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 18.0)
    }

    func featureDetailsFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 11.0)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
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
            height = 208.0
        case 1:
            height = 52.0
        case 2:
            switch indexPath.row {
            case 0:
                height = 82.0

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

    // MARK: - Core Data

    func processCoreDataNotification(notification: NSNotification) {
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for managedObject in updatedObjects {
                if managedObject is Artwork {
                    // Main table update
                    if self.contentItem?.artwork?.objectID == managedObject.objectID {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }



}
