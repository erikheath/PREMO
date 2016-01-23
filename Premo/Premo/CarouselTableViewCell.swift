//
//  CarouselTableViewCell.swift
//

import UIKit

class CarouselTableViewCell: UITableViewCell {

    @IBOutlet weak var carousel: iCarousel!
    
    @IBOutlet weak var carouselPageControl: UIPageControl!

    @IBOutlet weak var backgroundGradient: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        carousel.type = .Linear
        carousel.pagingEnabled = true
        self.backgroundGradient.image = self.backgroundImageMask()
    }

    func backgroundImageMask() -> UIImage? {

        let context = CIContext(options: [kCIContextUseSoftwareRenderer: false])
        let gradientFilter = CIFilter(name: "CISmoothLinearGradient")
        gradientFilter?.setDefaults()
        gradientFilter?.setValue(CIColor(color: UIColor.blackColor()), forKey: "inputColor1")
        gradientFilter?.setValue(CIColor(color: UIColor(colorLiteralRed: 40.0/255.0, green: 40.0/255.0, blue: 40.0/255.0, alpha: 1.0)), forKey: "inputColor0")
        gradientFilter?.setValue(CIVector(x: 0, y: -25), forKey: "inputPoint0")
        gradientFilter?.setValue(CIVector(x: 0, y: 50), forKey: "inputPoint1")
        guard let outputImageRecipe = gradientFilter?.outputImage else { return nil }
        let outputImage = context.createCGImage(outputImageRecipe, fromRect: self.frame)

        return UIImage(CGImage: outputImage)
    }

}
