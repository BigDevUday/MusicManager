//
//  DownloadManager.swift
//  AudioManager
//
//  Created by Uday on 30/09/22.
//

import Foundation

public enum DownloadDirectory : String {
    case music = "MusicDirectory"
    case video = "VideoDirectory"
}

class DownaloadServices : NSObject {
    
    static let shared = DownaloadServices()
    
    //MARK: type aliasis
    
    public typealias DownloadCompletionBlock = (_ error : Error?, _ fileUrl:URL?) -> Void
    public typealias DownloadProgressBlock = (_ progress : Float) -> Void
    public typealias BackgroundDownloadCompletionHandler = () -> Void
    
    //MARK: Private variables
    
    private var session: URLSession!
    private var ongoingDownloads: [String : Download] = [:]
    private var backgroundSession: URLSession!
    
    public var backgroundCompletionHandler: BackgroundDownloadCompletionHandler?
    public var showLocalNotificationOnBackgroundDownloadDone = true
    public var localNotificationText: String?
    
    
    //MARK: - Public methods
    
    public func downloadFile(withRequest request: URLRequest,
                             inDirectory directory: String? = nil,
                             withName fileName: String? = nil,
                             shouldDownloadInBackground: Bool = false,
                             onProgress progressBlock:DownloadProgressBlock? = nil,
                             onCompletion completionBlock:@escaping DownloadCompletionBlock) -> String? {
        
        guard let url = request.url else {
            debugPrint("Request url is empty")
            return nil
        }
        
        if let _ = self.ongoingDownloads[url.absoluteString] {
            debugPrint("Already in progress")
            return nil
        }
        
        let alreadySavedPath = Helper.cacheDirectoryPath().appendingPathComponent(directory!).appendingPathComponent(fileName!)
        
      
        let urlExtension: String? = url.pathExtension
        
        // to check if it exists before downloading it
        
        if FileManager.default.fileExists(atPath: alreadySavedPath.path) {
            return "The file already exists at path \(alreadySavedPath.path)"
            // if the file doesn't exist
        } else {
            // you can use NSURLSession.sharedSession to download the data asynchronously
            var downloadTask: URLSessionDownloadTask
            if shouldDownloadInBackground {
                downloadTask = self.backgroundSession.downloadTask(with: request)
            } else{
                downloadTask = self.session.downloadTask(with: request)
            }
            
            let download = Download(progressBlock: progressBlock, downloadTask: downloadTask,
                                    completionBlock: completionBlock,
                                    fileName: fileName,
                                    directoryName: directory, extensionOfFile: url.pathExtension)
            
            let key = self.getDownloadKey(withUrl: url)
            self.ongoingDownloads[key] = download
            downloadTask.resume()
            return key
        }
    }
    
    public func getDownloadKey(withUrl url: URL) -> String {
        return url.absoluteString
    }
    
    public func currentDownloads() -> [String] {
        return Array(self.ongoingDownloads.keys)
    }
    
    public func cancelAllDownloads() {
        for (_, download) in self.ongoingDownloads {
            let downloadTask = download.downloadTask
            downloadTask.cancel()
        }
        self.ongoingDownloads.removeAll()
    }
    
    public func cancelDownload(forUniqueKey key:String?) {
        let downloadStatus = self.isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                download.downloadTask.cancel()
                self.ongoingDownloads.removeValue(forKey: key!)
            }
        }
    }
    
    public func pause(forUniqueKey key:String?) {
        let downloadStatus = self.isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                let downloadTask = download.downloadTask
                downloadTask.suspend()
            }}
    }
    
    public func resume(forUniqueKey key:String?) {
        let downloadStatus = self.isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                let downloadTask = download.downloadTask
                downloadTask.resume()
            }}
    }
    
    public func isDownloadInProgress(forKey key:String?) -> Bool {
        let downloadStatus = self.isDownloadInProgress(forUniqueKey: key)
        return downloadStatus.0
    }
    
    public func alterDownload(withKey key: String?,
                              onProgress progressBlock:DownloadProgressBlock?,
                              onCompletion completionBlock:@escaping DownloadCompletionBlock) {
        let downloadStatus = self.isDownloadInProgress(forUniqueKey: key)
        let presence = downloadStatus.0
        if presence {
            if let download = downloadStatus.1 {
                download.progressBlock = progressBlock
                download.completionBlock = completionBlock
            }
        }
    }
    //MARK:- Private methods
    
    private override init() {
        super.init()
        let sessionConfiguration = URLSessionConfiguration.default
        self.session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        let backgroundConfiguration = URLSessionConfiguration.background(withIdentifier: Bundle.main.bundleIdentifier!)
        self.backgroundSession = URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: OperationQueue())
    }
    
    private func isDownloadInProgress(forUniqueKey key:String?) -> (Bool, Download?) {
        guard let key = key else { return (false, nil) }
        for (uniqueKey, download) in self.ongoingDownloads {
            if key == uniqueKey {
                return (true, download)
            }
        }
        return (false, nil)
    }
    
    private func getSaveFileUrl(fileName: URL) -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent((fileName.lastPathComponent))
        NSLog(fileURL.absoluteString)
        return fileURL;
    }
    
}

extension DownaloadServices : URLSessionDelegate, URLSessionDownloadDelegate {
    
    // MARK:- Delegates
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        
        let key = (downloadTask.originalRequest?.url)!
        if let download = self.ongoingDownloads[key.absoluteString]  {
            if let response = downloadTask.response {
                let statusCode = (response as! HTTPURLResponse).statusCode
                
                guard statusCode < 400 else {
                    let error = NSError(domain:"HttpError", code:statusCode, userInfo:[NSLocalizedDescriptionKey : HTTPURLResponse.localizedString(forStatusCode: statusCode)])
                    OperationQueue.main.addOperation({
                        download.completionBlock(error,nil)
                    })
                    return
                }
                
                let fileName = download.fileName ?? downloadTask.response?.suggestedFilename ?? (downloadTask.originalRequest?.url?.lastPathComponent)!
                let directoryName = download.directoryName
                let extensionOfItem = download.extensionOfFile ?? ""
                let fileMovingResult = Helper.moveFile(fromUrl: location, toDirectory: directoryName, withName: fileName, extensionOfFile: extensionOfItem)
                let didSucceed = fileMovingResult.0
                let error = fileMovingResult.1
                let finalFileUrl = fileMovingResult.2
                OperationQueue.main.addOperation({
                    (didSucceed ? download.completionBlock(nil,finalFileUrl) : download.completionBlock(error,nil))
                })
            }
        }
        self.ongoingDownloads.removeValue(forKey:key.absoluteString)
    }
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else {
            debugPrint("Could not calculate progress as totalBytesExpectedToWrite is less than 0")
            return;
        }
        
        if let download = self.ongoingDownloads[(downloadTask.originalRequest?.url?.absoluteString)!],
           let progressBlock = download.progressBlock {
            let progress : Float = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            OperationQueue.main.addOperation({
                progressBlock(progress)
            })
        }
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        
        if let error = error {
            let downloadTask = task as! URLSessionDownloadTask
            let key = (downloadTask.originalRequest?.url?.absoluteString)!
            if let download = self.ongoingDownloads[key] {
                OperationQueue.main.addOperation({
                    download.completionBlock(error,nil)
                })
            }
            self.ongoingDownloads.removeValue(forKey:key)
        }
    }
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            if downloadTasks.count == 0 {
                OperationQueue.main.addOperation({
                    if let completion = self.backgroundCompletionHandler {
                        completion()
                    }
                    
                    if self.showLocalNotificationOnBackgroundDownloadDone {
                        var notificationText = "Download completed"
                        if let userNotificationText = self.localNotificationText {
                            notificationText = userNotificationText
                        }
                        
                        Helper.showLocalNotification(withText: notificationText)
                    }
                    
                    self.backgroundCompletionHandler = nil
                })
            }
        }
    }
}
