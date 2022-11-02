//
//  VideoPlayer.swift
//  AudioManager
//
//  Created by Uday on 17/10/22.
//

import Foundation
import AVKit


class VideoPlayer : NSObject {

    // Base class just to execute basic functionality like play, seek
    
    public var player:AVPlayer?
    
    internal func didSeekBackTap(toSeconds:Int){
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
    
    
    internal func didSeekForwardTap(toSeconds:Int){
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
    
   internal func didPlayPauseButtonTapp()-> Bool{
        if player?.rate != 0
        {
            player!.pause()
            return false
        } else {
            player!.play()
            return true
        }
    }
    
    internal func speedChanger(_ value : Float, handler : (_ CanbeDone: Bool)->()){
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
    
    deinit {
        player?.removeObserver(self, forKeyPath: "rate")
    }
}

