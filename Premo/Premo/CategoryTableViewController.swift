//
//  CategoryTableViewController.swift
//

import UIKit
import CoreData
import CoreImage

class CategoryTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    lazy var managedObjectContext: NSManagedObjectContext? = (UIApplication.sharedApplication().delegate as! AppDelegate).datalayer?.mainContext

    var categoryObject: CategoryList? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func viewWillAppear(animated: Bool) {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        guard let navbarController = self.parentViewController as? UINavigationController else { return }
        navbarController.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "menu_fff")
        navbarController.navigationBar.backIndicatorImage = UIImage(named: "menu_fff")
        self.navigationItem.title = "PREMO"

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

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rowCount: Int
        if section == 0 {
            rowCount = 0
        } else {
            rowCount = (self.categoryObject?.contentItems?.count)! as Int ?? 0
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
//            let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
//            guard let objectString = object.valueForKey("categoryName")?.description?.uppercaseString else {
//                return
//            }
//            let mutableString = NSMutableAttributedString(string: objectString)
//            mutableString.addAttribute(NSFontAttributeName, value: self.categoryFont(), range: NSMakeRange(0, mutableString.length))
//            mutableString.addAttribute(NSKernAttributeName, value: NSNumber(float: 5.0), range: NSMakeRange(0, mutableString.length))
//            cell.textLabel!.attributedText = mutableString
//            cell.imageView?.image = UIImage(named: object.valueForKey("categoryIcon")!.description)
        } else {
            // POSTERCELL
            guard let posterCell = cell as? PosterTableViewCell else { return }
            guard let contentItem = self.categoryObject?.contentItems?[indexPath.row] as? ContentItem, let posterImageData = contentItem.artwork?.artwork269x152 else { return }
            let posterImage = UIImage(data: posterImageData)
            let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
            let gradientFilter = CIFilter(name: "CISmoothLinearGradient")
            gradientFilter?.setDefaults()
            gradientFilter?.setValue(CIColor(color: UIColor.blackColor()), forKey: "inputColor1")
            gradientFilter?.setValue(CIColor(color: UIColor.clearColor()), forKey: "inputColor0")
            gradientFilter?.setValue(CIVector(x: 150, y: 150), forKey: "inputPoint1")
            guard let outputImageRecipe = gradientFilter?.outputImage else { return }
            let outputImage = context.createCGImage(outputImageRecipe, fromRect: cell.bounds)
            let newImage = UIImage(CGImage: outputImage)
            let newImageView = UIImageView(image: newImage)
            posterCell.poster.image = posterImage
            posterCell.poster.maskView = newImageView

            guard var categoryName = self.categoryObject?.categoryName, var itemTitle = contentItem.contentDisplayHeader, let itemSubHeading = contentItem.contentDisplaySubheader else { return }

            categoryName = (categoryName as NSString).uppercaseString
            let mutableCategoryName = NSMutableAttributedString(string: categoryName)
            mutableCategoryName.addAttribute(NSFontAttributeName, value: self.categoryHeaderFont(), range: NSMakeRange(0, mutableCategoryName.length))
            posterCell.categoryLabel!.attributedText = mutableCategoryName

            itemTitle = (itemTitle as NSString).uppercaseString
            let mutableItemTitle = NSMutableAttributedString(string: itemTitle)
            mutableCategoryName.addAttribute(NSFontAttributeName, value: self.titleFont(), range: NSMakeRange(0, mutableCategoryName.length))
            posterCell.titleLabel!.attributedText = mutableItemTitle

            let mutableItemSubHeading = NSMutableAttributedString(string: itemSubHeading)
            mutableItemSubHeading.addAttribute(NSFontAttributeName, value: self.subHeadingFont(), range: NSMakeRange(0, mutableItemSubHeading.length))
            posterCell.subheadingLabel!.attributedText = mutableItemSubHeading

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
        return 152.0
    }


    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showContentDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                guard let object = categoryObject?.contentItems?.objectAtIndex(indexPath.row) as? ContentItem else { return }
                let controller = segue.destinationViewController as! FeatureTableViewController
                controller.contentItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
}
