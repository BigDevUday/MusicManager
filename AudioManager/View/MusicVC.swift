
import UIKit
import AVKit


enum mangerSelector {
    case audioManager
    case videoManager
}

class ViewController: UIViewController{

    @IBOutlet weak var sliderControlStack: UIStackView!
    @IBOutlet weak var featureControlStack: UIStackView!
    @IBOutlet weak var basicControlStack: UIStackView!
    
    @IBOutlet weak var albumCover: UIImageView!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var speedChanger: UIButton!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!

    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var buttonOutlet : UIButton!
    @IBOutlet weak var musicSlider: UISlider!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var beizerPathView : UIView!
    
    var songs = [Song]()
    var videos = [Video]()
    var manager : AudioPlayerManager!
    var downloadProgressView : DownloadProgressView?
    var managerSelector : mangerSelector = .audioManager
    var videoManager : VidoePlayerManager!
    var resumeOrPause = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startLabel.text = "--:--"
        endLabel.text = "--:--"
        setUpView(caseForManager: .audioManager)
        downloadProgressView = DownloadProgressView(frame: beizerPathView.bounds)
    }
    
    func setUpView(caseForManager: mangerSelector){
        
        switch caseForManager {
        case .audioManager:
            songs.append(Song(name: "kukushka.mp3", albumName: "Album 3", artistName: "Cold Play", imageName: "2", trackName: "https://www.kozco.com/tech/LRMonoPhase4.mp3", uniqueId: "", locallyAvailable: false, downloadedPercentage: 0.0))
            songs.append(Song(name: "Background music", albumName: "Album 1", artistName: "Rando", imageName: "1", trackName: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", uniqueId: "", locallyAvailable: false, downloadedPercentage: 0.0))
            songs.append(Song(name: "Havana", albumName: "Album 2", artistName: "Camibla", imageName: "3", trackName: "https://dl.espressif.com/dl/audio/ff-16b-1c-44100hz.mp3", uniqueId: "", locallyAvailable: false, downloadedPercentage: 0.0))
            songs.append(Song(name: "TestMusic", albumName: "Album 2", artistName: "Camibla", imageName: "4", trackName: "https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_500KB_MP3.mp3", uniqueId: "", locallyAvailable: false, downloadedPercentage: 0.0))
            manager = AudioPlayerManager(songs: songs)
            if manager.songs[manager.songPosition].locallyAvailable{
                self.downloadButton.setBackgroundImage(UIImage(named: "Right"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = false
            }
            else{
                self.downloadButton.setBackgroundImage(UIImage(named: "Download"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = true
            }
            setUpSlider()
            manager.updateLabels = { [weak self] currentTime, Endtime in
                self?.startLabel.text = currentTime
                self?.endLabel.text = Endtime
            }
            manager.updateProgress = { [weak self] time, progressedTime in
                self?.musicSlider?.value = Float ( time )
                print("<<",progressedTime)
            }
            
        case .videoManager:
            videos.append(Video(name: "Test", albumName: "albumTest", artistName: "TestArtist", imageName: "5", trackName: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", uniqueId: "", locallyAvailable: false))
            videos.append(Video(name: "Test", albumName: "albumTest", artistName: "TestArtist", imageName: "5", trackName: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4", uniqueId: "", locallyAvailable: false))
            videos.append(Video(name: "Test", albumName: "albumTest", artistName: "TestArtist", imageName: "5", trackName: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", uniqueId: "", locallyAvailable: false))
            videos.append(Video(name: "Test", albumName: "albumTest", artistName: "TestArtist", imageName: "5", trackName: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4", uniqueId: "", locallyAvailable: false))
            videoManager = VidoePlayerManager(videos: videos)
            videoManager.avpController?.view.frame = self.videoView.bounds
            self.videoView.addSubview(videoManager.avpController!.view)
            if videoManager.videos[videoManager.videoPosition].locallyAvailable{
                self.downloadButton.setBackgroundImage(UIImage(named: "Right"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = false
            }
              else{
                  self.downloadButton.setBackgroundImage(UIImage(named: "Download"), for: .normal)
                  self.downloadButton.isUserInteractionEnabled = true
              }
            
            
            videoManager.playPauseExternally = { status in
                if status {
                    self.buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
                }
                else {
                    self.buttonOutlet.setImage(UIImage(systemName: "play"), for: .normal)
                }
            }
            
            setUpSlider()
            
            videoManager.updateLabels = { [weak self] currentTime, Endtime in
                self?.startLabel.text = currentTime
                self?.endLabel.text = Endtime
            }
            videoManager.updateProgress = { [weak self] time, progressedTime in
                self?.musicSlider?.value = Float ( time )
                print("<<",progressedTime)
            }
        }
    }
    
    func setUpSlider(){
        musicSlider.minimumValue = 0
        musicSlider.maximumValue = 1
        let time : Float64?
        switch managerSelector {
        case .audioManager:
            time = CMTimeGetSeconds((self.manager.player?.player?.currentTime())!)
        case .videoManager:
            time  = CMTimeGetSeconds((self.videoManager.player?.player?.currentTime())!)
        }
        
        self.musicSlider!.value = Float ( time ?? 0.0 )
        musicSlider.isContinuous = false
        musicSlider.tintColor = .green
        musicSlider.addTarget(self, action: #selector(self.playbackSliderValueChanged(_:)), for: .valueChanged)
    }
    
    @IBAction func downloadButtonSong(_ sender: Any) {
        switch managerSelector {
        case .audioManager:
            resumeOrPause.toggle()
            if resumeOrPause {
                if  !manager.songs[manager.songPosition].uniqueId.isEmpty {
                    manager.resumeDownloading(key: manager.songs[manager.songPosition].uniqueId)
                }
                else {
                    manager.songs[manager.songPosition].uniqueId = manager.downloadSong(url: URL(string: manager.songs[manager.songPosition].trackName)!, nameForSaving: manager.songs[manager.songPosition].identifier) { error, fileUrl in
                        if error != nil {
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            print(fileUrl ?? "")
                        }
                    } progressHandler: { progress in
                        self.manager.songs[self.manager.songPosition].downloadedPercentage = progress
                        self.downloadProgressView?.updatePath(progressPoint: progress/10)
                        guard let downloadProgressView = self.downloadProgressView else {
                            return
                        }
                        self.beizerPathView.addSubview(downloadProgressView)
                        self.beizerPathView.isHidden = false
                        if progress == 100 {
                            self.beizerPathView.isHidden = true
                            self.downloadButton.setBackgroundImage(UIImage(named: "Right"), for: .normal)
                            self.downloadButton.isUserInteractionEnabled = false
                        }
                        print("\(progress)%")
                    }
                }
            }
            else {
                manager.pauseDownloading(key: manager.songs[manager.songPosition].uniqueId )
            }
            
            
        case .videoManager:
            resumeOrPause.toggle()
            if resumeOrPause {
                if  !videoManager.videos[videoManager.videoPosition].uniqueId.isEmpty {
                    videoManager.resumeDownloading(key: videoManager.videos[videoManager.videoPosition].uniqueId)
                }
                else {
                    videoManager.videos[videoManager.videoPosition].uniqueId = videoManager.downloadSong(url: URL(string: videoManager.videos[videoManager.videoPosition].trackName)!, nameForSaving: videoManager.videos[videoManager.videoPosition].identifier) { error, fileUrl in
                        if error != nil {
                            print(error?.localizedDescription ?? "")
                        }
                        else{
                            print(fileUrl ?? "")
                        }
                    } progressHandler: { progress in
                        self.videoManager.videos[self.videoManager.videoPosition].downloadedPercentage = progress
                        self.downloadProgressView?.updatePath(progressPoint: progress/10)
                        guard let downloadProgressView = self.downloadProgressView else {
                            return
                        }
                        self.beizerPathView.addSubview(downloadProgressView)
                        self.beizerPathView.isHidden = false
                        if progress == 100 {
                            self.beizerPathView.isHidden = true
                            self.downloadButton.setBackgroundImage(UIImage(named: "Right"), for: .normal)
                            self.downloadButton.isUserInteractionEnabled = false
                        }
                        print("\(progress)%")
                    }
                }
            }
            else {
                videoManager.pauseDownloading(key: videoManager.videos[videoManager.videoPosition].uniqueId )
            }
        }
            
            
    }
    
    @IBAction func seekNextButton(_ sender: Any) {
        switch managerSelector {
        case .audioManager:
            manager.didSeekForwardTap(toSeconds: 10)
            buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
        case .videoManager:
            videoManager.player?.didSeekForwardTap(toSeconds: 10)
        }
    }
    
    @IBAction func seekBackButton(_ sender: Any) {
        switch managerSelector {
        case .audioManager:
            manager.didSeekBackTap(toSeconds: 10)
            buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
        case .videoManager:
            videoManager.player?.didSeekBackTap(toSeconds: 10)
        }
    }
    @IBAction func nextButton(_ sender: Any) {
        switch managerSelector {
        case .audioManager:
            manager.didNextButtonTapp()
            beizerPathView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            DispatchQueue.main.async {
                self.downloadProgressView?.updatePath(progressPoint: self.manager.songs[self.manager.songPosition].downloadedPercentage/10)
            }
            if manager.songs[manager.songPosition].locallyAvailable{
                self.downloadButton.setBackgroundImage(UIImage(named: "Right"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = false
            }
            else{
                resumeOrPause = false
                self.downloadButton.setBackgroundImage(UIImage(named: "Download"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = true
            }
            buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
        case .videoManager:
            self.videoManager.avpController?.view.removeFromSuperview()
            self.videoManager.avpController = nil
            videoManager.didNextButtonTapp()
            videoManager.avpController?.view.frame = self.videoView.bounds
            self.videoView.addSubview(videoManager.avpController!.view)
            beizerPathView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            DispatchQueue.main.async {
                self.downloadProgressView?.updatePath(progressPoint: (self.videoManager.videos[self.videoManager.videoPosition].downloadedPercentage ?? 0.0)/10)
            }
            if videoManager.videos[videoManager.videoPosition].locallyAvailable{
                self.downloadButton.setBackgroundImage(UIImage(named: "Right"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = false
            }
            else{
                resumeOrPause = false
                self.downloadButton.setBackgroundImage(UIImage(named: "Download"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = true
            }
        }
    }
    @IBAction func backButton(_ sender: Any) {
        switch managerSelector {
        case .audioManager:
            manager.didBackButtonTapp()
            beizerPathView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            DispatchQueue.main.async {
                self.downloadProgressView?.updatePath(progressPoint: self.manager.songs[self.manager.songPosition].downloadedPercentage/10)
            }
            if manager.songs[manager.songPosition].locallyAvailable{
                self.downloadButton.setBackgroundImage(UIImage(named: "Right"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = false
            }
            else{
                resumeOrPause = false
                self.downloadButton.setBackgroundImage(UIImage(named: "Download"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = true
            }
            buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
        case .videoManager:
            self.videoManager.avpController?.view.removeFromSuperview()
            self.videoManager.avpController = nil
            videoManager.didBackButtonTapp()
            videoManager.avpController?.view.frame = self.videoView.bounds
            self.videoView.addSubview(videoManager.avpController!.view)
            beizerPathView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            DispatchQueue.main.async {
                self.downloadProgressView?.updatePath(progressPoint: (self.videoManager.videos[self.videoManager.videoPosition].downloadedPercentage ?? 0.0)/10)
            }
            if videoManager.videos[videoManager.videoPosition].locallyAvailable{
                self.downloadButton.setBackgroundImage(UIImage(named: "Right"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = false
            }
            else{
                resumeOrPause = false
                self.downloadButton.setBackgroundImage(UIImage(named: "Download"), for: .normal)
                self.downloadButton.isUserInteractionEnabled = true
            }
        }
    }
    @IBAction func playButton(_ sender: Any) {
        switch managerSelector {
        case .audioManager:
            if manager.didPlayPauseButtonTapp(){
                buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
            }
            else{
                buttonOutlet.setImage(UIImage(systemName: "play"), for: .normal)
            }
        case .videoManager:
            if videoManager.player?.didPlayPauseButtonTapp() ?? false{
                buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
            }
            else{
                buttonOutlet.setImage(UIImage(systemName: "play"), for: .normal)
            }
        }
    }
    
    
    @IBAction func loopOn(_ sender: Any) {
        switch managerSelector {
        case .audioManager:
            manager.isLoopEnabled = true
        case .videoManager:
            videoManager.isLoopEnabled = true
        }
    }
    
    @IBAction func shuffleOn(_ sender: Any) {
        switch managerSelector {
        case .audioManager:
            manager.isShuffleEnabled = true
        case .videoManager:
            videoManager.isShuffleEnabled = true
        }
    }
    
    @IBAction func speedChanger(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        let newSpeed = Float(0.5)
        switch managerSelector {
        case .audioManager:
            if sender.isSelected {
                manager.speedChanger(newSpeed) { ifPossible in
                    if ifPossible{
                        speedChanger.setTitle("\(newSpeed)", for: .normal)
                        buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
                        print("possible")
                    }
                    else{
                        print("not possible")
                    }
                }
            }
            else {
                let newSpeed = Float(1.0)
                manager.speedChanger(newSpeed) { ifPossible in
                    if ifPossible{
                        speedChanger.setTitle("\(newSpeed)", for: .normal)
                        buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
                        print("possible")
                    }
                    else{
                        print("not possible")
                    }
                }
            }
        case .videoManager:
            if sender.isSelected {
                videoManager.player?.speedChanger(newSpeed) { ifPossible in
                    if ifPossible{
                        speedChanger.setTitle("\(newSpeed)", for: .normal)
                        buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
                        print("possible")
                    }
                    else{
                        print("not possible")
                    }
                }
            }
            else {
                let newSpeed = Float(1.0)
                videoManager.player?.speedChanger(newSpeed) { ifPossible in
                    if ifPossible{
                        speedChanger.setTitle("\(newSpeed)", for: .normal)
                        buttonOutlet.setImage(UIImage(systemName: "pause"), for: .normal)
                        print("possible")
                    }
                    else{
                        print("not possible")
                    }
                }
            }
        }
    }
 
    
    @objc func playbackSliderValueChanged(_ playbackSlider:UISlider)
    {
        
        switch managerSelector {
        case .audioManager:
            manager.timeChanged(sliderValue: playbackSlider.value)

        case .videoManager:
            videoManager.timeChanged(sliderValue: playbackSlider.value)

        }
        
    }
    
}

