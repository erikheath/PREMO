//
//  DetailPosterTableViewCell.swift
//

import UIKit

class DetailPosterTableViewCell: UITableViewCell {

    @IBOutlet weak var readyToPlayButton: UIButton!
    
    @IBOutlet weak var subscribeToPlayButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    
}
