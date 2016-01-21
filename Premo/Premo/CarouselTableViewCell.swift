//
//  CarouselTableViewCell.swift
//

import UIKit

class CarouselTableViewCell: UITableViewCell {

    @IBOutlet weak var carousel: iCarousel!
    
    @IBOutlet weak var carouselPageControl: UIPageControl!

    @IBOutlet weak var backgroundGradient: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        carousel.type = .Linear
        carousel.pagingEnabled = true

    }
}
