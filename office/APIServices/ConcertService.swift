//
//  ConcertService.swift
//  office
//
//  Created by Sujay Patwardhan on 4/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import Foundation
import APIManager

extension Data: APIReturnable {
    public init(from data: Data) {
        self = data
    }
}

final class ConcertService: GrootService {
    override class var baseURL: String {
        return "https://concert.acm.illinois.edu"
    }

    static func createSessionFor(user username: String, withPassword password: String) -> APIRequest<Data> {
        var body = HTTPBody()
        body["username"] = username
        body["password"] = password
        
        return APIRequest<Data>(service: self, endpoint: "/login", body: body, method: .POST)
    }
}
