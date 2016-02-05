//
//  ControllerTableViewCell.swift
//

import UIKit

class ControllerTableViewCell: UITableViewCell {

    weak var delegate: UIViewController?

    @IBOutlet weak var playTrailerButton: UIButton!

    @IBOutlet weak var shareFeatureButton: UIButton!

    @IBOutlet weak var dividerView: UIView!

    @IBOutlet weak var shareLeadingMargin: NSLayoutConstraint!

    @IBOutlet weak var shareButtonWidth: NSLayoutConstraint!

    @IBOutlet weak var shareLeadingPosition: NSLayoutConstraint!

    @IBOutlet weak var shareTrailingPosition: NSLayoutConstraint!

    @IBAction func shareFeature(sender: AnyObject) -> Void {
        guard let viewController = self.delegate as? FeatureTableViewController, let title = viewController.contentItem?.contentDetailDisplayTitle, let titleImageData = viewController.contentItem?.artwork?.artwork269x152, let titleImage = UIImage(data: titleImageData) else { return }
        var sharingItems = [AnyObject]()

        sharingItems.append("Check out \(title) on PREMO. You can download PREMO from the Apple App Store.")
        sharingItems.append(titleImage)
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.delegate!.presentViewController(activityViewController, animated: true, completion: nil)
    }

    func configureOneButtonLayout() -> Void {
        guard let leadingMargin = self.shareLeadingMargin, let leadingPosition = self.shareLeadingPosition, let buttonWidth = self.shareButtonWidth else { return }
        self.shareFeatureButton.removeConstraints([leadingMargin, leadingPosition, buttonWidth])
        self.playTrailerButton.removeFromSuperview()
        self.dividerView.removeFromSuperview()

        self.contentView.addConstraint(NSLayoutConstraint(item: self.shareFeatureButton, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.LeadingMargin, multiplier: 1.0, constant: 0.0))

    }


}
