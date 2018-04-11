//
//  GrootSerivce.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import Foundation
import APIManager 
class GrootService: APIService {
    open class var baseURL: String {
        return "https://api.acm.illinois.edu"
    }

    static var headers: HTTPHeaders {
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization": APISecrets.GROOT_CLIENT_KEY
        ]
    }
}

final class GrootSessionService: GrootService {
    override static var baseURL: String {
        return super.baseURL + "/session"
    }

    static func createSessionFor(user username: String, withPassword password: String) -> APIRequest<ACMSession> {
        var validationFactors = HTTPBody()
        validationFactors["value"] = "127.0.0.1"
        validationFactors["name"] = "remote_address"

        var validation_factors = HTTPBody()
        validation_factors["validationFactors"] = [validationFactors]

        var body = HTTPBody()
        body["username"] = username
        body["password"] = password
        body["validation-factors"] = validation_factors

        return APIRequest<ACMSession>(service: self, endpoint: "", body: body, method: .POST)
    }
}
