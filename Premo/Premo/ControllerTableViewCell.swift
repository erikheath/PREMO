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

        sharingItems.append(titleImage)
        sharingItems.append("Check out \(title) on PREMO. You can download PREMO from the Apple App Store.")
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.delegate!.presentViewController(activityViewController, animated: true, completion: nil)
    }

    func configureOneButtonLayout() -> Void {
        self.shareFeatureButton.removeConstraints([self.shareLeadingMargin, self.shareLeadingPosition, self.shareButtonWidth, self.shareTrailingPosition])
        self.contentView.removeConstraints([self.shareTrailingPosition])
        self.playTrailerButton.removeFromSuperview()
        self.dividerView.removeFromSuperview()

        self.contentView.addConstraint(NSLayoutConstraint(item: self.shareFeatureButton, attribute: NSLayoutAttribute.LeftMargin, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.LeftMargin, multiplier: 1.0, constant: -2.0))
        self.contentView.addConstraint(NSLayoutConstraint(item: self.shareFeatureButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Width, multiplier: 0.5, constant: 0.0))
        
    }


}
