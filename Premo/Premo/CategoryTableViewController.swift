//
//  CategoryTableViewController.swift
//

import UIKit
import CoreData
import CoreImage

class CategoryTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, iCarouselDataSource, CarouselDelegate {

    lazy var managedObjectContext: NSManagedObjectContext? = (UIApplication.sharedApplication().delegate as! AppDelegate).datalayer?.mainContext

    var categoryObjectName: String? = nil

    var categoryListImageMask: UIImage? = nil

    var carouselViewDimensions: CGRect = CGRectMake(0.0, 0.0, 0.0, 0.0)

    var carouselImageMask: UIImage? = nil

    weak var carouselTimer: NSTimer? = nil

    var carouselPaused: Bool = false

    // MARK: - OBJECT LIFECYCLE

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if self.carouselTimer != nil {
            self.carouselTimer?.invalidate()
            self.carouselTimer = nil
        }
    }

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

    func configureNavigationItemAppearance() {
        navigationItemSetup: do {
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "  ", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = self.categoryObjectName
            if let title = self.categoryObjectName where self.categoryObjectName != "Featured" {
                self.navigationItem.titleView = PremoStyleTemplate.styledTitleLabel(title)
            } else {
                let titleViewImageView = UIImageView(image: UIImage(named: "PREMO_titlebar"))
                titleViewImageView.contentMode = .ScaleAspectFit
                self.navigationItem.titleView = titleViewImageView
            }
            self.navigationItem.hidesBackButton = true

        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            PremoStyleTemplate.styleVisibleNavBar(navbarController.navigationBar)
            navbarController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "back")
            navbarController.navigationBar.backIndicatorImage = UIImage(named: "back")
            navbarController.navigationBarHidden = false
        }

        revealControllerSetup: do {
            guard let revealController = self.revealViewController() else {
                break revealControllerSetup
            }
            let toggleButton = UIBarButtonItem(title: "toggle", style: .Plain, target: revealController, action: "revealToggle:")
            toggleButton.image = UIImage(named: "menu_fff")
            self.navigationItem.leftBarButtonItem = toggleButton
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processCoreDataNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: self.managedObjectContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processCoreDataNotification:", name: NSManagedObjectContextDidSaveNotification, object: self.managedObjectContext)
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        self.setNeedsStatusBarAppearanceUpdate()

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        (self.revealViewController() as? SlideController)!.blackStatusBarBackgroundView?.backgroundColor = UIColor.blackColor()

        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
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

    // MARK: - iCarousel Data Source

    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        guard let carouselSet = (self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel else { return 0 }

        return carouselSet.count
    }

    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView {
        guard let carouselView = view as? CarouselView ?? NSBundle.mainBundle().loadNibNamed("CarouselView", owner: self, options: Dictionary<NSObject, AnyObject>())[0] as? CarouselView else { return UIView() }
        carouselView.frame = self.carouselViewDimensions
        guard index < (self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel?.count else { return carouselView }
        guard let contentItemID = ((self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel?[index] as? CarouselItem)?.contentSourceID else {
            return carouselView }
        // To get the correct content items, I need to search the currentlist.
        let contentItemIndex = ((self.fetchedResultsController.fetchedObjects)! as NSArray).indexOfObjectPassingTest({ (object: AnyObject, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            if (object as? ContentItem)!.contentSourceID == contentItemID { return true }
            return false
        })
        if contentItemIndex == NSNotFound { return carouselView }
        guard let contentItem = self.fetchedResultsController.fetchedObjects?[contentItemIndex] as? ContentItem else {return carouselView }

        carouselView.categoryLabel!.attributedText = self.contentItemGenre(contentItem)

        if var itemTitle = contentItem.contentDisplayHeader {
            itemTitle = (itemTitle as NSString).uppercaseString
            let mutableItemTitle = NSMutableAttributedString(string: itemTitle)
            mutableItemTitle.addAttribute(NSFontAttributeName, value: self.carouselTitleFont(), range: NSMakeRange(0, mutableItemTitle.length))
            mutableItemTitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableItemTitle.length))
            carouselView.titleLabel!.attributedText = mutableItemTitle
        }

        if let itemSubHeading = contentItem.contentDisplaySubheader {
            let mutableItemSubHeading = NSMutableAttributedString(string: itemSubHeading)
            mutableItemSubHeading.addAttribute(NSFontAttributeName, value: self.subHeadingFont(), range: NSMakeRange(0, mutableItemSubHeading.length))
            carouselView.subheadingLabel!.attributedText = mutableItemSubHeading
        }

        guard let posterImageData = contentItem.artwork?.artwork269x152 else { return carouselView }
        let posterImage = UIImage(data: posterImageData)
        let maskImageView = UIImageView(image: self.carouselImageMask(carouselView.poster.bounds))
        carouselView.poster.image = posterImage
        carouselView.poster.maskView = maskImageView

        return carouselView
    }

    // MARK: - iCarousel Delegate

    func carousel(carousel: iCarousel, shouldSelectItemAtIndex index: Int) -> Bool {
        return true
    }

    func carousel(carousel: iCarousel, didSelectItemAtIndex index: Int) {

        guard index < (self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel?.count else { return }
        guard let contentItemID = ((self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel?[index] as? CarouselItem)?.contentSourceID else {
            return }
        // To get the correct content items, I need to search the currentlist.
        let contentItemIndex = ((self.fetchedResultsController.fetchedObjects)! as NSArray).indexOfObjectPassingTest({ (object: AnyObject, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            if (object as? ContentItem)!.contentSourceID == contentItemID { return true }
            return false
        })
        if contentItemIndex == NSNotFound { return }
        guard let contentItem = self.fetchedResultsController.fetchedObjects?[contentItemIndex] as? ContentItem else {return }
        guard let featureDetailController = self.storyboard?.instantiateViewControllerWithIdentifier("FeatureTableViewController") as? FeatureTableViewController else { return }
        featureDetailController.contentItem = contentItem
        self.navigationController?.pushViewController(featureDetailController, animated: true)
        return
    }

    func carouselCurrentItemIndexDidChange(carousel: iCarousel) {
        guard let carouselCell = carousel.superview?.superview as? CarouselTableViewCell else { return }
        carouselCell.carouselPageControl.currentPage = carousel.currentItemIndex
        self.animateCarousel(false)
    }

    func animateCarousel(unpause: Bool) -> Void {
        if self.carouselTimer != nil {
            self.carouselTimer?.invalidate()
            self.carouselTimer = nil
        }
        guard self.carouselPaused == false || unpause == true else { return }
        self.carouselTimer = NSTimer.scheduledTimerWithTimeInterval(6.0, target: self, selector: "showNextCarouselItem:", userInfo: nil, repeats: false)
    }

    func pauseCarouselAnimation() -> Void {
        if self.carouselTimer != nil {
            self.carouselTimer?.invalidate()
            self.carouselTimer = nil
        }
        self.carouselPaused = true
    }

    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        switch option {
        case .Wrap:
            return 1.0
        default:
            return value
        }
    }

    func carouselShouldReloadData(carousel: iCarousel) -> Bool {
        guard let carouselSet = (self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel where carouselSet.count > 0 else { return false }
        for item in carouselSet {
            guard let carouselItem = item as? CarouselItem, let carouselSourceID = carouselItem.contentSourceID else { return false }
            let contentObjects = (fetchedResultsController.fetchedObjects as NSArray!).filteredArrayUsingPredicate(NSPredicate(format: "contentSourceID == %@", argumentArray: [carouselSourceID]))
            guard let contentItem = contentObjects.first as? ContentItem else { return false }
            if contentItem.artwork?.artwork269x152 == nil {
                return false
            }
        }
        return true
    }

    func carouselWillReloadData(carousel: iCarousel) {
        if self.carouselTimer != nil {
            self.carouselTimer?.invalidate()
            self.carouselTimer = nil
        }
    }

    func carouselDidReloadData(carousel: iCarousel) {
        if carousel.numberOfItems == 0 { return }
        self.animateCarousel(false)
        guard let carouselCell = carousel.superview?.superview as? CarouselTableViewCell else { return }
        carouselCell.carouselPageControl.numberOfPages = carouselCell.carousel.numberOfItems
        carouselCell.carouselPageControl.currentPage = carouselCell.carousel.currentItemIndex
    }

    func showNextCarouselItem(timer: NSTimer) {
        let targetIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        guard ((self.tableView.indexPathsForVisibleRows as NSArray!).contains { (object: AnyObject) -> Bool in
            guard let indexPath = object as? NSIndexPath else { return false }
            if indexPath == targetIndexPath { return true }
            return false
        }) == true else { return }
        guard let cell = self.tableView.cellForRowAtIndexPath(targetIndexPath) as? CarouselTableViewCell else { return }
        cell.carousel.scrollByNumberOfItems(1, duration: 1.5)
    }

    // MARK: - TABLE VIEW DATA SOURCE

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount: Int
        if section == 0 && self.categoryObjectName == AppDelegate.defaultCategory {
            rowCount = 1
        } else if section == 0 {
            rowCount = (self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel?.count > 0 ? 1 : 0
        } else {
            rowCount = (self.fetchedResultsController.sections?[section - 1].numberOfObjects)! ?? 0
        }
        return rowCount


    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("CarouselCell", forIndexPath: indexPath)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("PosterCell", forIndexPath: indexPath)
        }

        self.configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            guard let carouselCell = cell as? CarouselTableViewCell else { return }
            self.carouselViewDimensions = cell.bounds
            carouselCell.carousel.delegate = self
            carouselCell.carousel.dataSource = self
            carouselCell.backgroundGradient.backgroundColor = nil

        } else {
            // POSTERCELL
            let modifiedPath = NSIndexPath(forRow: indexPath.row, inSection: indexPath.section - 1)
            guard let posterCell = cell as? PosterTableViewCell else { return }
            guard let contentItem = self.fetchedResultsController.objectAtIndexPath(modifiedPath) as? ContentItem else { return }

            posterCell.categoryLabel!.attributedText = self.contentItemGenre(contentItem)

            if var itemTitle = contentItem.contentDisplayHeader {
                itemTitle = (itemTitle as NSString).uppercaseString
                let mutableItemTitle = NSMutableAttributedString(string: itemTitle)
                mutableItemTitle.addAttribute(NSFontAttributeName, value: self.categoryTitleFont(), range: NSMakeRange(0, mutableItemTitle.length))

                mutableItemTitle.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange( 0, mutableItemTitle.length))
                posterCell.titleLabel!.attributedText = mutableItemTitle
            }

            if let itemSubHeading = contentItem.contentDisplaySubheader {
                let mutableItemSubHeading = NSMutableAttributedString(string: itemSubHeading)
                mutableItemSubHeading.addAttribute(NSFontAttributeName, value: self.subHeadingFont(), range: NSMakeRange(0, mutableItemSubHeading.length))
                posterCell.subheadingLabel!.attributedText = mutableItemSubHeading
            }

            guard let posterImageData = contentItem.artwork?.artwork269x152 else { return }
            let posterImage = UIImage(data: posterImageData)
            let maskImageView = UIImageView(image: self.categoryListImageMask(cell.bounds))
            posterCell.poster.image = posterImage
            posterCell.poster.maskView = maskImageView

        }
    }

    func contentItemGenre(contentItem: ContentItem) -> NSAttributedString {
        guard let genreObject = contentItem.genres?.firstObject as? Genre, var genreName = genreObject.genreName, var genreColorString = genreObject.genreColor  else { return NSAttributedString() }

        genreName = (genreName as NSString).uppercaseString
        let mutableGenreName = NSMutableAttributedString(string: genreName)
        mutableGenreName.addAttribute(NSFontAttributeName, value: self.categoryHeaderFont(), range: NSMakeRange(0, mutableGenreName.length))

        let genreStringRange = NSMakeRange(5, (genreColorString as NSString).length - 6)
        genreColorString = (genreColorString as NSString).substringWithRange(genreStringRange)
        let colorArray: Array<NSString> = (genreColorString as NSString).componentsSeparatedByString(", ") as Array<NSString>
        if colorArray.count == 4 {
            let genreColor = UIColor(colorLiteralRed: colorArray[0].floatValue / 255.0, green: colorArray[1].floatValue / 255.0, blue: colorArray[2].floatValue / 255.0, alpha: colorArray[3].floatValue)
            mutableGenreName.addAttribute(NSForegroundColorAttributeName, value: genreColor, range: NSMakeRange(0, mutableGenreName.length))
        }

        return mutableGenreName
    }

    func carouselImageMask(rect: CGRect) -> UIImage? {
        if self.carouselImageMask == nil {
            let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
            let gradientFilter = CIFilter(name: "CISmoothLinearGradient")
            gradientFilter?.setDefaults()
            gradientFilter?.setValue(CIColor(color: UIColor.blackColor()), forKey: "inputColor1")
            gradientFilter?.setValue(CIColor(color: UIColor.clearColor()), forKey: "inputColor0")
            gradientFilter?.setValue(CIVector(x: 0, y: -20), forKey: "inputPoint0")
            gradientFilter?.setValue(CIVector(x: 0, y: 220), forKey: "inputPoint1")
            guard let outputImageRecipe = gradientFilter?.outputImage else { return nil }
            let outputImage = context.createCGImage(outputImageRecipe, fromRect: rect)
            self.carouselImageMask = UIImage(CGImage: outputImage)
        }

        return self.carouselImageMask
    }

    func categoryListImageMask(rect: CGRect) -> UIImage? {
        if self.categoryListImageMask == nil {
            let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
            let gradientFilter = CIFilter(name: "CISmoothLinearGradient")
            gradientFilter?.setDefaults()
            gradientFilter?.setValue(CIColor(color: UIColor.blackColor()), forKey: "inputColor1")
            gradientFilter?.setValue(CIColor(color: UIColor.clearColor()), forKey: "inputColor0")
            gradientFilter?.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint0")
            gradientFilter?.setValue(CIVector(x: 300, y: 300), forKey: "inputPoint1")
            guard let outputImageRecipe = gradientFilter?.outputImage else { return nil }
            let outputImage = context.createCGImage(outputImageRecipe, fromRect: rect)
            self.categoryListImageMask = UIImage(CGImage: outputImage)
        }

        return self.categoryListImageMask
    }

    func carouselTitleFont() -> UIFont {
        //        let newFont = UIFont(name: "Helvetica-Regular", size: 16)
        let newFont = UIFont.systemFontOfSize(16)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 16)
    }

    func categoryTitleFont() -> UIFont {
        //        let newFont = UIFont(name: "Helvetica-Regular", size: 16)
        let newFont = UIFont.systemFontOfSize(16)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 16)
    }

    func subHeadingFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Light", size: 11)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 12)
    }

    func categoryHeaderFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 9)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 9)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 357.0
        } else {
            return 211.0
        }
    }


    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showContentDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let modifiedPath = NSIndexPath(forRow: indexPath.row, inSection: indexPath.section - 1)
                guard let object = self.fetchedResultsController.objectAtIndexPath(modifiedPath) as? ContentItem else { return }
                let controller = segue.destinationViewController as! FeatureTableViewController
                controller.contentItem = object
            }
        }
    }

    // MARK: - Core Data

    func processCoreDataNotification(notification: NSNotification) {
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for managedObject in updatedObjects {
                if managedObject is Artwork {
                    // Main table update
                    guard let paths = self.tableView.indexPathsForVisibleRows else { continue }
                    for indexPath in paths {
                        if (self.fetchedResultsController.sections?[0].objects?[indexPath.row] as? ContentItem)!.artwork?.objectID == managedObject.objectID {
                            print("reload data from update artwork")
                            self.tableView.reloadData()
                        }
                    }
                    // Carousel update
                    guard let carouselSet = (self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel else { continue }
                    for item in carouselSet {
                        guard let carouselItem = item as? CarouselItem, let managedObjectsArray = self.fetchedResultsController.fetchedObjects as NSArray!, let carouselSourceID = carouselItem.contentSourceID else { break }
                        let object = managedObjectsArray.filteredArrayUsingPredicate(NSPredicate(format: "contentSourceID == %@", argumentArray: [carouselSourceID]))
                        guard let contentItem = object.first as? ContentItem else { break }
                        if contentItem.artwork?.objectID == managedObject.objectID {
                            guard let carouselCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? CarouselTableViewCell else { continue }
                            carouselCell.carousel.reloadData()
                        }
                    }
                }
            }
        }

        if let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
            for managedObject in insertedObjects {
                if managedObject is CarouselItem {
                    if let carouselCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? CarouselTableViewCell {
                        carouselCell.carousel.reloadData()
                    }
                }
            }

        }
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }

        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        //        let mom = (UIApplication.sharedApplication().delegate as! AppDelegate).datalayer?.persistentStoreCoordinator.managedObjectModel
        //        let entity = mom?.entitiesByName["CategoryList"]
        let entity = NSEntityDescription.entityForName("ContentItem", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        fetchRequest.includesSubentities = true
        fetchRequest.returnsObjectsAsFaults = false

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "remoteOrderPosition", ascending: true)

        fetchRequest.sortDescriptors = [sortDescriptor]

        // Edit the search predicate.
        if let categoryName = self.categoryObjectName {
            fetchRequest.predicate = NSPredicate(format: "categoryMember.categoryName = %@", argumentArray: [categoryName])
        }

        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: self.categoryObjectName)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController

        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            print("Unresolved error \(error)")
        }

        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex + 1), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex + 1), withRowAnimation: .Fade)
        default:
            return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        var modifiedPath:NSIndexPath? = nil
        var modifiedNewPath:NSIndexPath? = nil
        if indexPath != nil {
            modifiedPath = NSIndexPath(forRow: (indexPath?.row)!, inSection: (indexPath?.section)! + 1)
        }
        if newIndexPath != nil {
            modifiedNewPath = NSIndexPath(forRow: (newIndexPath?.row)!, inSection: (newIndexPath?.section)! + 1)
        }
        switch type {
        case .Insert:
            guard let _ = modifiedNewPath else { return }
            tableView.insertRowsAtIndexPaths([modifiedNewPath!], withRowAnimation: .Fade)
        case .Delete:
            guard let _ = modifiedPath else { return }
            tableView.deleteRowsAtIndexPaths([modifiedPath!], withRowAnimation: .Fade)
        case .Update:
            guard let _ = modifiedPath, let cell = tableView.cellForRowAtIndexPath(modifiedPath!) else { return }
            self.configureCell(cell, atIndexPath: modifiedPath!)
        case .Move:
            guard let _ = modifiedPath, let _ = modifiedNewPath else { return }
            tableView.deleteRowsAtIndexPaths([modifiedPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([modifiedNewPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    
}
