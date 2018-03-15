//
//  ACMConcertPlayState.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import Foundation

struct ACMConcertPlayState: Decodable {
    let isPlaying: Bool
    let currentTime: Int
    let duration: Int

    enum CodingKeys: String, CodingKey {
        case isPlaying = "is_playing"
        case currentTime = "current_time"
        case duration
    }
}
