//
//  ACMApplicationController.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import Foundation
import APIManager

class ACMApplicationController {
    static let shared = ACMApplicationController()
    private init() { }

//    var session: ACMSession?
//    var cookies: HTTPCookies?
    var extractedCookies = [HTTPCookie]()

}

struct ACMSession: APIReturnable, Decodable {
    let token: String
}

struct ConcertSession: APIReturnable, Decodable {
    let session: String
}
