//
//  ControllerTableViewCell.swift
//

import UIKit

class ControllerTableViewCell: UITableViewCell {

    weak var delegate: UIViewController?

    @IBOutlet weak var playTrailerButton: UIButton!

    @IBOutlet weak var shareFeatureButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func shareFeature(sender: AnyObject) {
        guard let viewController = self.delegate as? FeatureTableViewController, let title = viewController.contentItem?.contentDetailDisplayTitle, let titleImageData = viewController.contentItem?.artwork?.artwork269x152, let titleImage = UIImage(data: titleImageData) else { return }
        var sharingItems = [AnyObject]()

        sharingItems.append(titleImage)
        sharingItems.append("\n\nCheck out \(title) on PREMO. You can download PREMO from the Apple App Store.")
        let activityViewController = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
        self.delegate!.presentViewController(activityViewController, animated: true, completion: nil)
    }

    @IBAction func playTrailer(sender: AnyObject) {

    }
}
