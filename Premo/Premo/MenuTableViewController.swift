//
//  MenuTableViewController.swift
//

import UIKit
import CoreData

class MenuTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    lazy var managedObjectContext: NSManagedObjectContext? = (UIApplication.sharedApplication().delegate as! AppDelegate).datalayer?.mainContext

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
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.navigationItem.title = ""
            self.navigationItem.hidesBackButton = true
        }
    }

    func configureNavigationBarAppearance() {
        navbarControllerSetup: do {
            guard let navbarController = self.parentViewController as? UINavigationController else { break navbarControllerSetup }
            navbarController.navigationBarHidden = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        self.tableView.clipsToBounds = true
        self.tableView.superview?.clipsToBounds = true


    }

    override func viewWillAppear(animated: Bool) {
        self.configureNavigationItemAppearance()
        self.configureNavigationBarAppearance()
        (self.revealViewController() as? SlideController)!.blackStatusBarBackgroundView?.backgroundColor = UIColor.blackColor()

        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()


    }

    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let identifier = segue.identifier else { return }
        switch identifier {
            case "showCategory":
            if let indexPath = self.tableView.indexPathForSelectedRow {
                guard let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as? CategoryList else {
                    return
                }
                guard let controller = segue.destinationViewController as? AppRoutingNavigationController else { return }
                controller.currentNavigationStack = AppRoutingNavigationController.NavigationStack.videoStack
                controller.currentCategoryName = object.categoryName
            }
        case "showAccount":
            guard let controller = segue.destinationViewController as? AppRoutingNavigationController else { return }
            controller.currentNavigationStack = AppRoutingNavigationController.NavigationStack.accountStack
        default:
            return // Add Error handling
        }
        guard let navbarController = self.parentViewController as? UINavigationController else { return }
        navbarController.navigationBarHidden = false

    }


    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Add +1 for the custom account section.
        return (self.fetchedResultsController.sections?.count)! + 1 ?? 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Account is added as a separate section.
        let rowCount: Int
        if section == 0 {
            let sectionInfo = self.fetchedResultsController.sections![section]
            rowCount = sectionInfo.numberOfObjects
        } else {
            rowCount = 1
        }
        return rowCount
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableView.dequeueReusableCellWithIdentifier("CategoryCell", forIndexPath: indexPath)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath)
        }

        self.configureCell(cell, atIndexPath: indexPath)

        return cell
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
            guard let objectString = object.valueForKey("categoryName")?.description?.uppercaseString else {
                return
            }
            let mutableString = NSMutableAttributedString(string: objectString)
            mutableString.addAttribute(NSFontAttributeName, value: self.categoryFont(), range: NSMakeRange(0, mutableString.length))
            mutableString.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableString.length))
            cell.textLabel!.attributedText = mutableString
            cell.imageView?.image = UIImage(named: object.valueForKey("categoryIcon")!.description)
            cell.imageView?.frame = CGRect(x: (cell.imageView?.frame.origin.x)! + 4.0, y: (cell.imageView?.frame.origin.y)!, width: (cell.imageView?.frame.size.width)!, height: (cell.imageView?.frame.size.height)!)

        } else {
            cell.imageView?.image = UIImage(named: "account")
            let mutableString = NSMutableAttributedString(string: "ACCOUNT")
            mutableString.addAttribute(NSFontAttributeName, value: self.categoryFont(), range: NSMakeRange(0, mutableString.length))
            mutableString.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableString.length))
            cell.textLabel!.attributedText = mutableString
        }
    }

    func categoryFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 12)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 12)
    }

    func categoryHeaderFont() -> UIFont {
        let newFont = UIFont(name: "Montserrat-Regular", size: 10)
        let descriptorDict = (newFont?.fontDescriptor().fontAttributes()[UIFontDescriptorTraitsAttribute]) as? [NSObject : AnyObject] ?? Dictionary()
        let newFontAttributes = NSMutableDictionary(dictionary: descriptorDict)
        let fontDescriptor = newFont?.fontDescriptor().fontDescriptorByAddingAttributes(NSDictionary(dictionary: newFontAttributes) as! [String : AnyObject])
        return UIFont(descriptor: fontDescriptor!, size: 10)
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Returns a view loaded from a xib for the header.
        let categoryView: UIView
        if section == 0 {
            categoryView = NSBundle.mainBundle().loadNibNamed("CategorySectionLabel", owner: self, options: nil)[0] as! UILabel
            (categoryView as! UILabel).font = self.categoryHeaderFont()
            guard let attributedString = (categoryView as! UILabel).attributedText else { return categoryView }
            let mutableString = NSMutableAttributedString(attributedString: attributedString)
            mutableString.addAttribute(NSBaselineOffsetAttributeName, value: NSNumber(float: -2.75), range: NSMakeRange(0, mutableString.length))
            mutableString.addAttribute(NSKernAttributeName, value: NSNumber(float: 1.0), range: NSMakeRange(0, mutableString.length))
//            let paragraphStyle = NSMutableParagraphStyle()
//            paragraphStyle.setParagraphStyle(NSParagraphStyle.defaultParagraphStyle())
//            paragraphStyle.firstLineHeadIndent = 16.0
//            mutableString.addAttribute(NSParagraphStyleAttributeName, value: paragraphStyle, range: NSMakeRange(0, mutableString.length))
            (categoryView as! UILabel).attributedText = NSAttributedString(attributedString: mutableString)
            let coverview = UIView(frame: CGRect(x: 0.0, y: -160.0, width: self.tableView.frame.width, height: 160.0))
            coverview.backgroundColor = categoryView.backgroundColor
            categoryView.addSubview(coverview)
        } else {
            categoryView = NSBundle.mainBundle().loadNibNamed("AccountSectionLabel", owner: self, options: nil)[0] as! UIView
        }
        return categoryView
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let height: CGFloat
        if section == 0 {
            height = 27.0
        } else {
            height = 1.0
        }
        return height
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 63.0
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
        let entity = NSEntityDescription.entityForName("CategoryList", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20

        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "remoteOrderPosition", ascending: true)

        fetchRequest.sortDescriptors = [sortDescriptor]

        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
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
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Update:
            guard let _ = indexPath, let cell = tableView.cellForRowAtIndexPath(indexPath!) else { return }
            self.configureCell(cell, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }


}
