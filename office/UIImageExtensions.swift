//
//  ACMApplicationController.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import UIKit
import GPUImage

public extension UIImage {
    public func blur(radius: CGFloat) -> UIImage? {
        let blur = GPUImageiOSBlurFilter()
        blur.blurRadiusInPixels = radius
        return blur.image(byFilteringImage: self)
    }
}
