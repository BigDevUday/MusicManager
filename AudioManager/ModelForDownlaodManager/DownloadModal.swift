//
//  DownloadModal.swift
//  AudioManager
//
//  Created by Uday on 30/09/22.
//

import Foundation


class Download {
    let downloadTask: URLSessionDownloadTask
    var completionBlock: DownaloadServices.DownloadCompletionBlock
    var progressBlock: DownaloadServices.DownloadProgressBlock?
    let directoryName: String?
    let fileName:String?
    let extensionOfFile: String?
    
    init(progressBlock: DownaloadServices.DownloadProgressBlock?,downloadTask: URLSessionDownloadTask,
         completionBlock: @escaping DownaloadServices.DownloadCompletionBlock, fileName: String?,
         directoryName: String?,extensionOfFile:String?) {
        self.completionBlock = completionBlock
        self.progressBlock = progressBlock
        self.downloadTask = downloadTask
        self.fileName = fileName
        self.directoryName = directoryName
        self.extensionOfFile = extensionOfFile

    }
}
