//
//  Videos.swift
//  AudioManager
//
//  Created by Uday on 07/10/22.
//

import Foundation


struct Video {
    let name : String
    let albumName: String
    let artistName: String
    let imageName: String
    let trackName: String
    var uniqueId : String
    var locallyAvailable : Bool
    var downloadedPercentage : Float?
    var identifier : String {
        return URL(string: self.trackName)?.deletingPathExtension().lastPathComponent ?? ""
    }
}

