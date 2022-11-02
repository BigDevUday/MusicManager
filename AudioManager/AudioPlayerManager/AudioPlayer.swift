//
//  AudioPlayer.swift
//  AudioManager
//
//  Created by Uday on 17/10/22.
//

import UIKit
import AVFoundation
import MediaPlayer


class AudioPlayer: NSObject {
    
    var player:AVPlayer?
    
    func speedChanger(_ value : Float, handler : (_ CanbeDone: Bool)->()){
        if value > 0 {
            if player?.currentItem?.canPlayFastForward == true{
                player?.rate = value
                handler(true)
            }
            else {
                handler(false)
            }
        }
        else {
            if player?.currentItem?.canPlaySlowForward == true{
                player?.rate = value
                handler(true)
            }
            else {
                handler(false)
            }
        }
    }
    
    func didSeekBackTap(toSeconds:Int){
        let time : Float64 = CMTimeGetSeconds(self.player!.currentTime())
        let seconds : Int64 = Int64(round(time))
        let targetTime:CMTime = CMTimeMake(value: seconds - Int64(toSeconds), timescale: 1)
        player!.seek(to: targetTime)
        if player!.rate == 0
        {
            player?.play()
        } else {
            
        }
    }
    func didSeekForwardTap(toSeconds:Int){
        let time : Float64 = CMTimeGetSeconds(self.player!.currentTime())
        let seconds : Int64 = Int64(round(time))
        let targetTime:CMTime = CMTimeMake(value: seconds + Int64(toSeconds), timescale: 1)
        player!.seek(to: targetTime)
        if player!.rate == 0
        {
            player?.play()
        } else {
        }
    }

    func didPlayPauseButtonTapp()-> Bool{
        if player?.rate != 0
        {
            player!.pause()
            return false
        } else {
            player!.play()
            return true
        }
    }

}
