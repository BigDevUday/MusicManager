//
//  SongModel.swift
//  AudioManager
//
//  Created by Uday on 28/09/22.
//

import Foundation
struct Song {
    let name : String
    let albumName: String
    let artistName: String
    let imageName: String
    let trackName: String
    var uniqueId : String
    var locallyAvailable : Bool
    var downloadedPercentage : Float
    var identifier : String {
        return URL(string: self.trackName)?.deletingPathExtension().lastPathComponent ?? ""
    }
    
}

// Sample Model For Music
