//
//  ACMTintImageView.swift
//  office
//
//  Created by Sujay Patwardhan on 4/20/18.
//  Copyright © 2018 acm. All rights reserved.
//

import Foundation
import UIKit

class ACMTintImageView: UIImageView {
    override var image: UIImage? {
        get {
            return super.image
        }
        set {
            super.image = newValue
            initialize()
        }
    }
    
    override var tintColor: UIColor! {
        get {
            return super.tintColor
        }
        set {
            super.tintColor = newValue
            initialize()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    func initialize() {
        guard let image = image else { return }
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        tintColor.setFill()
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.translateBy(x: 0, y: image.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        
        let rect = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
        guard let mask = image.cgImage else { return }
        context.clip(to: rect, mask: mask)
        context.fill(rect)
        super.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
}
