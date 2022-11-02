//
//  AudioPlayerManager.swift
//  AudioManager
//
//  Created by Uday on 28/09/22.
//

//
//  PlayerVC.swift
//  MusicPlayer
//
//  Created by Shivaditya Kumar on 15/03/22.
//

import UIKit
import AVFoundation
import MediaPlayer


class AudioPlayerManager: NSObject {
   
    public typealias DownloadCompletionBlock = (_ error : Error?, _ fileUrl:URL?) -> Void
    public typealias DownloadProgressBlock = (_ progress : Float) -> Void
    public typealias BackgroundDownloadCompletionHandler = () -> Void
    
    private let commandCenter = MPRemoteCommandCenter.shared()
    public var songPosition: Int = 0
    public var songs: [Song] = []
    var updateLabels : ((String,String)->())?
    var updateProgress : ((CGFloat,Int)->())?
    
    var isLoopEnabled : Bool?
    var isShuffleEnabled : Bool?
    
//    var player:AVPlayer?
    var player : AudioPlayer?
    var playerItem:AVPlayerItem?
    
    init(songs : [Song]) {
        super.init()
        self.songs = songs
        configure()
    }
    
    
    func configure(){
        self.player = AudioPlayer()
        let song = songs[songPosition]
        let extensionForItem = ".\(URL(string: songs[songPosition].trackName)?.pathExtension ?? "")"
        if isDataDownloadedWith(filename: songs[songPosition].identifier, extensionItem: extensionForItem){
            getDownloadedSong(filename: songs[songPosition].identifier, extensionItem: extensionForItem)
                    songs[songPosition].locallyAvailable = true
            print("locally found")
        }
        else {
            let url = URL(string: song.trackName )
            let playerItem:AVPlayerItem = AVPlayerItem(url: url!)
            player?.player = AVPlayer(playerItem: playerItem)
        }
        progressStatusForSeekBar()
        setUpObserver()
    }
    
    
    func progressStatusForSeekBar(){
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
                self.setCommandTargets()
            }
        }
    }
    
    
    func speedChanger(_ value : Float, handler : (_ CanbeDone: Bool)->()){
        
        if value > 0 {
            if player?.player?.currentItem?.canPlayFastForward == true{
                player?.player?.rate = value
                handler(true)
            }
            else {
                handler(false)
            }
        }
        else {
            if player?.player?.currentItem?.canPlaySlowForward == true{
                player?.player?.rate = value
                handler(true)
            }
            else {
                handler(false)
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
    
    
    
    private func setCommandTargets() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
        } catch let error as NSError {
            print("Setting category to AVAudioSessionCategoryPlayback failed: \(error)")
        }
        
        
        var nowPlayingInfo = [String : Any]()
        if let image = UIImage(named: "play") {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { size in
                return image
            }
        }
        nowPlayingInfo[MPMediaItemPropertyTitle] = songs[songPosition].name
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.player?.currentItem?.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player?.player?.currentItem?.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.player?.rate
        
        // Set the metadata
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        commandCenter.playCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.player?.player?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.player?.player?.pause()
            return .success
        }
        
        commandCenter.skipBackwardCommand.addTarget(self, action: #selector(handleSkipBackwardCommandEvent(event:)))
        
        commandCenter.skipForwardCommand.addTarget(self, action: #selector(handleSkipForwardCommandEvent(event:)))
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            print("posion: \(positionEvent.positionTime)")
            let targetTime:CMTime = CMTimeMake(value: Int64(positionEvent.positionTime), timescale: 1)
            self?.player?.player?.seek(to: targetTime)
            self?.player?.player?.play()
            return .success
        }
    }
    
    @objc func handleSkipForwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        didSeekForwardTap(toSeconds: 10)
        return .success
    }
    
    @objc func handleSkipBackwardCommandEvent(event: MPSkipIntervalCommandEvent) -> MPRemoteCommandHandlerStatus {
        didSeekBackTap(toSeconds:10)
        return .success
    }
    
    func setUpObserver(){
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.player?.player?.currentItem, queue: .main) { _ in
            if self.isLoopEnabled ?? false{
                self.enableLoop()
            }
            else{
                if self.isShuffleEnabled ?? false {
                    self.enableShuffle()
                }
                else{
                    self.didNextButtonTapp()
                }
            }
        }
        
    }
    
    func enableLoop(){
        self.player?.player?.seek(to: CMTime.zero)
        self.player?.player?.play()
    }
    
    func enableShuffle(){
        isLoopEnabled = false
        songPosition = Int.random(in: 0...songs.count)
    }
    
    func didSeekBackTap(toSeconds:Int){
        player?.didSeekBackTap(toSeconds: toSeconds)
    }
    func didSeekForwardTap(toSeconds:Int){
        player?.didSeekForwardTap(toSeconds: toSeconds)
    }
    
    func didNextButtonTapp(){
        if songPosition < (songs.count - 1) {
            songPosition = songPosition + 1
            player?.player?.pause()
            self.configure()
            self.player?.player?.play()
        }
        else if (songPosition == songs.count - 1) {
            songPosition = 0
            player?.player?.pause()
            self.configure()
            self.player?.player?.play()
        }
    }
    func didBackButtonTapp(){
        if songPosition > 0 {
            songPosition = songPosition - 1
            player?.player?.pause()
            self.configure()
            self.player?.player?.play()
        }
        else if songPosition == 0 {
            songPosition = songs.count - 1
            player?.player?.pause()
            self.configure()
            self.player?.player?.play()
        }
    }
    func didPlayPauseButtonTapp()-> Bool{
        player?.didPlayPauseButtonTapp() ?? false
    }
    
    
    
    // get already downloaded data
    
    func getDownloadedSong(filename : String,extensionItem:String){
        let newUrl = "\(Helper.cacheDirectoryPath().appendingPathComponent(DownloadDirectory.music.rawValue).appendingPathComponent(filename + extensionItem).path)"
        playerItem = AVPlayerItem(url: NSURL.fileURL(withPath: newUrl))
        player?.player = AVPlayer(playerItem: playerItem)
    }
    
    
    // return true if song is already downloaded
    
    func isDataDownloadedWith(filename : String,extensionItem:String) -> Bool {
        let newUrl = "\(Helper.cacheDirectoryPath().appendingPathComponent(DownloadDirectory.music.rawValue).appendingPathComponent(filename + extensionItem).path)"
        do {
            _ = try Data(contentsOf: NSURL.fileURL(withPath: newUrl))
            return true
        } catch {
            return false
        }
    }
    
    //Just give the Position of current array list
    func downloadSong(listPosition: Int,nameForSaving:String,completionHandler: @escaping DownloadCompletionBlock,progressHandler:@escaping DownloadProgressBlock) -> String{
        let name = DownaloadServices.shared.downloadFile(withRequest: URLRequest(url:URL(string: songs[listPosition].trackName)!), inDirectory: DownloadDirectory.music.rawValue, withName: "\(songs[listPosition].name)", shouldDownloadInBackground: true) { progress in
            progressHandler(progress*100)
        } onCompletion: { error, fileUrl in
            completionHandler(error,fileUrl)
        }
        return name ?? ""
    }
    
    //by url here
    
    func downloadSong(url:URL,nameForSaving:String,completionHandler: @escaping DownloadCompletionBlock,progressHandler:@escaping DownloadProgressBlock) -> String {
        let name = DownaloadServices.shared.downloadFile(withRequest: URLRequest(url:url), inDirectory: DownloadDirectory.music.rawValue, withName: nameForSaving, shouldDownloadInBackground: true) { progress in
            progressHandler(progress*100)
        } onCompletion: { error, fileUrl in
            completionHandler(error,fileUrl)
        }
        return name ?? ""
    }
    
    func resumeDownloading(key: String) {
        DownaloadServices.shared.resume(forUniqueKey: key)
    }
    
    func pauseDownloading(key: String) {
        DownaloadServices.shared.pause(forUniqueKey: key)
    }
    
    
}
