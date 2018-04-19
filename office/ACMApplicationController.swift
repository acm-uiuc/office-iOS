//
//  ACMApplicationController.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import Foundation
import APIManager
import UIImageColors

class ACMApplicationController {
    static let shared = ACMApplicationController()
    private init() { }

//    var session: ACMSession?
//    var cookies: HTTPCookies?
    var extractedCookies = [HTTPCookie]()
    var defaultPalette = UIImageColors(
        background: UIColor.white,
        primary: UIColor.black,
        secondary: UIColor.blue,
        detail: UIColor.black
    )

}

struct ACMSession: APIReturnable, Decodable {
    let token: String
}

struct ConcertSession: APIReturnable, Decodable {
    let session: String
}
