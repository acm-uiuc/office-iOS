//
//  ACMConcertStatus.swift
//  office
//
//  Created by Rauhul Varma on 2/11/18.
//  Copyright © 2018 acm. All rights reserved.
//

import APIManager

struct ACMConcertStatus: Decodable {
    let audioStatus: String?
    let volume: Int?
    let isPlaying: Bool?
    let currentTime: Int?
    let duration: Int?
    let currentTrack: String?
    let thumbnail: String?

    enum CodingKeys: String, CodingKey {
        case audioStatus = "audio_status"
        case volume
        case isPlaying = "is_playing"
        case currentTime = "current_time"
        case duration
        case currentTrack = "current_track"
        case thumbnail
    }
}
