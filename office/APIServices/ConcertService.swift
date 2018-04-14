//
//  ConcertService.swift
//  office
//
//  Created by Sujay Patwardhan on 4/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

//import Foundation
//import APIManager
//class ConcertService: GrootService {
//    override class var baseURL: String {
//        return "https://concert.acm.illinois.edu"
//    }
//
//}
//
//final class ConcertSessionService: ConcertService {
//    override static var baseURL: String {
//        return super.baseURL
//    }
//
//    static func createSessionFor(user username: String, withPassword password: String) -> APIRequest<ConcertSession> {
//        var body = HTTPBody()
//        body["username"] = username
//        body["password"] = password
//
//        return APIRequest<ConcertSession>(service: self, endpoint: "/login", body: body, method: .POST)
//    }
//}
