//
//  Carousel.swift
//

import UIKit



@objc protocol CarouselDelegate: iCarouselDelegate {

    optional func carouselWillReloadData(carousel: iCarousel) -> Void

    optional func carouselShouldReloadData(carousel: iCarousel) -> Bool

    optional func carouselDidReloadData(carousel: iCarousel) -> Void

}

class Carousel: iCarousel {

    override func reloadData() {
        guard let carouselDelegate = self.delegate as? CarouselDelegate else {
            super.reloadData()
            return
        }
        guard carouselDelegate.respondsToSelector("carouselShouldReloadData:") == false || carouselDelegate.carouselShouldReloadData?(self) == true else {
            return
        }
        carouselDelegate.carouselWillReloadData?(self)
        super.reloadData()
        carouselDelegate.carouselDidReloadData?(self)
    }
    
}
