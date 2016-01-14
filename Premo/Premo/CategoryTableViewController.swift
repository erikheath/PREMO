//
//  CategoryTableViewController.swift
//

import UIKit
import CoreData
import CoreImage

class CategoryTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, iCarouselDataSource, iCarouselDelegate {

    lazy var managedObjectContext: NSManagedObjectContext? = (UIApplication.sharedApplication().delegate as! AppDelegate).datalayer?.mainContext

    var categoryObjectName: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processCoreDataNotification:", name: NSManagedObjectContextObjectsDidChangeNotification, object: self.managedObjectContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "processCoreDataNotification:", name: NSManagedObjectContextDidSaveNotification, object: self.managedObjectContext)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        guard let navbarController = self.parentViewController as? UINavigationController else { return }
        navbarController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "menu_fff")
        navbarController.navigationBar.backIndicatorImage = UIImage(named: "menu_fff")
        self.navigationItem.title = "PREMO"
        navbarController.navigationBarHidden = false


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

    // MARK: - iCarousel Data Source

    func numberOfItemsInCarousel(carousel: iCarousel) -> Int {
        guard let carouselSet = (self.fetchedResultsController.fetchedObjects?.first as? ContentItem)?.categoryMember?.carousel else { return 0 }

        return carouselSet.count
    }

    func carousel(carousel: iCarousel, viewForItemAtIndex index: Int, reusingView view: UIView?) -> UIView {
        return UIView()
    }

    // MARK: - iCarousel Delegate

    func carousel(carousel: iCarousel, shouldSelectItemAtIndex index: Int) -> Bool {
        return true
    }

    func carousel(carousel: iCarousel, didSelectItemAtIndex index: Int) {
        return
    }

    func carousel(carousel: iCarousel, valueForOption option: iCarouselOption, withDefault value: CGFloat) -> CGFloat {
        switch option {
        case .Wrap:
            return 1.0
        default:
            return value
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount: Int
        if section == 0 {
            rowCount = 1
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

        } else {
            // POSTERCELL
            let modifiedPath = NSIndexPath(forRow: indexPath.row, inSection: indexPath.section - 1)
            guard let posterCell = cell as? PosterTableViewCell else { return }
            guard let contentItem = self.fetchedResultsController.objectAtIndexPath(modifiedPath) as? ContentItem else { return }

            if let genreObject = contentItem.genres?.firstObject as? Genre, var genreName = genreObject.genreName, var genreColorString = genreObject.genreColor {
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

                posterCell.categoryLabel!.attributedText = mutableGenreName
            } else {
                posterCell.categoryLabel!.text = ""
            }
            if var itemTitle = contentItem.contentDisplayHeader {
                itemTitle = (itemTitle as NSString).uppercaseString
                let mutableItemTitle = NSMutableAttributedString(string: itemTitle)
                mutableItemTitle.addAttribute(NSFontAttributeName, value: self.titleFont(), range: NSMakeRange(0, mutableItemTitle.length))
                posterCell.titleLabel!.attributedText = mutableItemTitle
            }

            if let itemSubHeading = contentItem.contentDisplaySubheader {
                let mutableItemSubHeading = NSMutableAttributedString(string: itemSubHeading)
                mutableItemSubHeading.addAttribute(NSFontAttributeName, value: self.subHeadingFont(), range: NSMakeRange(0, mutableItemSubHeading.length))
                posterCell.subheadingLabel!.attributedText = mutableItemSubHeading
            }

            guard let posterImageData = contentItem.artwork?.artwork269x152 else { return }

            let posterImage = UIImage(data: posterImageData)
            let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
            let gradientFilter = CIFilter(name: "CISmoothLinearGradient")
            gradientFilter?.setDefaults()
            gradientFilter?.setValue(CIColor(color: UIColor.blackColor()), forKey: "inputColor1")
            gradientFilter?.setValue(CIColor(color: UIColor.clearColor()), forKey: "inputColor0")
            gradientFilter?.setValue(CIVector(x: 0, y: 0), forKey: "inputPoint0")
            gradientFilter?.setValue(CIVector(x: 175, y: 175), forKey: "inputPoint1")
            guard let outputImageRecipe = gradientFilter?.outputImage else { return }
            let outputImage = context.createCGImage(outputImageRecipe, fromRect: cell.bounds)
            let newImage = UIImage(CGImage: outputImage)
            let newImageView = UIImageView(image: newImage)
            posterCell.poster.image = posterImage
            posterCell.poster.maskView = newImageView

        }
    }

    func titleFont() -> UIFont {
//        let newFont = UIFont(name: "Helvetica-Regular", size: 16)
        let newFont = UIFont.systemFontOfSize(16)
        let descriptorDict = (newFont.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor, size: 12)
    }

    func subHeadingFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Light", size: 11)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 50.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 12)
    }

    func categoryHeaderFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 10)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        newFontAttributes.setValue(NSNumber(float: 100.0), forKey: NSKernAttributeName)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 10)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 211.0
    }


    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showContentDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let modifiedPath = NSIndexPath(forRow: indexPath.row, inSection: indexPath.section - 1)
                guard let object = self.fetchedResultsController.objectAtIndexPath(modifiedPath) as? ContentItem else { return }
                let controller = segue.destinationViewController as! FeatureTableViewController
                controller.contentItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Core Data

    func processCoreDataNotification(notification: NSNotification) {
        if let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
            for managedObject in updatedObjects {
                if managedObject is Artwork {
                    guard let paths = self.tableView.indexPathsForVisibleRows else { continue }
                    for indexPath in paths {
                        if (self.fetchedResultsController.sections?[0].objects?[indexPath.row] as? ContentItem)!.artwork?.objectID == managedObject.objectID {
                            print("reload data from update artwork")
                            self.tableView.reloadData()
                        }
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
