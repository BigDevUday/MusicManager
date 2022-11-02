//
//  videoPlayerManager.swift
//  AudioManager
//
//  Created by Uday on 03/10/22.
//

import Foundation
import AVKit

class VidoePlayerManager : NSObject {
    
    //MARK: type aliases -
    public typealias DownloadCompletionBlock = (_ error : Error?, _ fileUrl:URL?) -> Void
    public typealias DownloadProgressBlock = (_ progress : Float) -> Void
    public typealias BackgroundDownloadCompletionHandler = () -> Void
    
    
    //MARK: General references for updating UI
    public var playPauseExternally : ((Bool) -> Void)?
    public var videoPosition: Int = 0
    public var videos: [Video] = []
    public var updateLabels : ((String,String)->())?
    public var updateProgress : ((CGFloat,Int)->())?
    public var isLoopEnabled : Bool?
    public var isShuffleEnabled : Bool?
    
    
    //MARK: player initialization
    public var player : VideoPlayer?
    public var avpController : AVPlayerViewController?

    fileprivate var playerItem:AVPlayerItem?
    fileprivate var playerLayer: AVPlayerLayer?
    fileprivate var timeControlStatusObserver: NSKeyValueObservation?

    
    //MARK: class initialization
    init(videos : [Video]){
        super.init()
        self.videos = videos
        self.player = VideoPlayer()
        configure() //
    }
    
    
    // configure every avplayer item
    fileprivate func configure(){
        
        let urlExtension = ".\(URL(string:videos[videoPosition].trackName)?.pathExtension ?? "")"
//        self.player?.player = nil // to mak
        if isDataDownloadedWith(filename: videos[videoPosition].identifier, extensionItem: urlExtension ){
            getDownloadedSong(filename: videos[videoPosition].identifier, extensionItem: urlExtension)
            videos[videoPosition].locallyAvailable = true
            print("locally found")
        }
        else{
            let song = videos[videoPosition]
            let url = URL(string: song.trackName)
            player?.player = AVPlayer(url: url!)
            avpController = AVPlayerViewController()
            avpController?.player = player?.player
        }
        // closure and observer setUp
        progressStatusForSeekBar()
        setUpObserver()
    }
    
    
    //MARK: Observer For rate change
    fileprivate func setUpObserver() {
        player?.player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        // how can we remove the observer
    }
    
    
    public func didNextButtonTapp(){
        if videoPosition < (videos.count - 1) {
            videoPosition = videoPosition + 1 // increase the position by 1 when next is tapped
            player?.player?.pause()
            self.configure()
            self.player?.player?.play()
        }
        else if (videoPosition == videos.count - 1) {
            videoPosition = 0
            player?.player?.pause()
            self.configure()
            self.player?.player?.play()
        }
    }
    
    
    public func didBackButtonTapp(){
        if videoPosition > 0 {
            videoPosition = videoPosition - 1 // decrease the position by 1 when next is tapped
            player?.player?.pause()
            self.configure()
            self.player?.player?.play()
        }
        else if videoPosition == 0 {
            videoPosition = videos.count - 1
            player?.player?.pause()
            self.configure()
            self.player?.player?.play()
        }
    }
    
    //Just give the Position of current array list
    public func downloadSong(listPosition: Int,nameForSaving:String,completionHandler: @escaping DownloadCompletionBlock,progressHandler:@escaping DownloadProgressBlock) -> String{
            let name = DownaloadServices.shared.downloadFile(withRequest: URLRequest(url:URL(string: videos[listPosition].trackName)!), inDirectory: DownloadDirectory.video.rawValue, withName: "\(videos[listPosition].name)", shouldDownloadInBackground: false) { progress in
                progressHandler(progress*100) // download percentage
            } onCompletion: { error, fileUrl in
                completionHandler(error,fileUrl) // completion handler on success
            }
            return name ?? ""
        }
    
    //by url here
    
    public func downloadSong(url:URL,nameForSaving:String,completionHandler: @escaping DownloadCompletionBlock,progressHandler:@escaping DownloadProgressBlock) -> String{
            let name = DownaloadServices.shared.downloadFile(withRequest: URLRequest(url:url), inDirectory: DownloadDirectory.video.rawValue, withName: nameForSaving, shouldDownloadInBackground: false) { progress in
                progressHandler(progress*100)
            } onCompletion: { error, fileUrl in
                completionHandler(error,fileUrl)
            }
            return name ?? ""
    }
    
    
    // get already downloaded data
    
    func getDownloadedSong(filename : String,extensionItem:String){
        let newUrl = "\(Helper.cacheDirectoryPath().appendingPathComponent(DownloadDirectory.video.rawValue).appendingPathComponent(filename + extensionItem).path)"
        player?.player = AVPlayer(url: NSURL.fileURL(withPath: newUrl))
        avpController = AVPlayerViewController()
        avpController?.player = player?.player
    }
    
    
    // return true if song is already downloaded
    
    func isDataDownloadedWith(filename : String,extensionItem:String) -> Bool {
        let newUrl = "\(Helper.cacheDirectoryPath().appendingPathComponent(DownloadDirectory.video.rawValue).appendingPathComponent(filename + extensionItem).path)"
        do {
            _ = try Data(contentsOf: NSURL.fileURL(withPath: newUrl))
            return true
        } catch {
            return false
        }
    }
    
    // Resume Download
    func resumeDownloading(key: String) {
        DownaloadServices.shared.resume(forUniqueKey: key)
    }
    
    //Pause Download
    func pauseDownloading(key: String) {
        DownaloadServices.shared.pause(forUniqueKey: key)
    }
    
    
    // seekbar update external
    
    public func progressStatusForSeekBar(){
        player?.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: DispatchQueue.main) { (CMTime) -> Void in
            if self.player?.player?.currentItem?.status == .readyToPlay {
                guard let bufferTime = self.player?.player?.currentItem?.loadedTimeRanges.last?.timeRangeValue.duration.value else {
                    return
                }
                let bufferTime1 = Int64(self.player?.player?.currentItem?.loadedTimeRanges.last?.timeRangeValue.duration.timescale ?? 0)
                let progressedTillNow = Int(bufferTime/bufferTime1)
                let time : Float64 = CMTimeGetSeconds((self.player?.player?.currentTime())!)
                let endTime : Float64 = CMTimeGetSeconds((self.player?.player?.currentItem!.duration)!)
                let secs = Int(time)
                let endSecs = Int(endTime)
                let secInString = NSString(format: "%02d:%02d", secs/60, secs%60) as String
                let endSecInString = NSString(format: "%02d:%02d", endSecs/60, endSecs%60) as String
                self.updateLabels?(secInString,endSecInString)
                self.updateProgress?(CGFloat(time/endTime),progressedTillNow)
            }
        }
    }
    
    func timeChanged(sliderValue: Float){
        let seconds = sliderValue * Float(player?.player?.currentItem?.duration.seconds ?? 0)
        let targetTime:CMTime = CMTimeMake(value: Int64(seconds), timescale: 1)
        player?.player?.pause()
        player?.player?.seek(to: targetTime)
        player?.player?.play()
    }

    
    // setUp task on rate change
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if player?.player?.rate ?? 0 > 0 {
                playPauseExternally?(true)
                print("video started")
            }
            else {
                playPauseExternally?(false)
                print("video paused")
            }
        }
    }
}

