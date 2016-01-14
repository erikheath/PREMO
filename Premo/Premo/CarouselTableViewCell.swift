//
//  CarouselTableViewCell.swift
//

import UIKit

class CarouselTableViewCell: UITableViewCell {

    @IBOutlet weak var carousel: iCarousel!

    override func awakeFromNib() {
        super.awakeFromNib()
        carousel.type = .Linear
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
