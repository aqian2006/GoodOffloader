//
//  GoodDownloadManager.swift
//  GoodOffloader
//
//  Created by Abbott on 4/3/17.
//  Copyright © 2017 Waseda Univ. All rights reserved.
//

import Foundation

public let kGoodDownloadSessionIdentifier = "gooddownloadmanager_downloads"


public let kGoodDownloadErrorDomain = "com.waseda.cheng.zhang.GoodOffloader.error"
public let kGoodDownloadErrorDescriptionKey = "TCBlobDownloadErrorDescriptionKey"
public let kGoodDownloadErrorHTTPStatusKey = "TCBlobDownloadErrorHTTPStatusKey"
public let kGoodDownloadErrorFailingURLKey = "TCBlobDownloadFailingURLKey"


public enum GoodDownloadError: Int {
    case GoodDownloadHTTPError = 1
}


public class GoodDownloadManager{
    
    public static let sharedInstance = GoodDownloadManager()
    
    /// The DownlaodDelegate 
    private let delegate : DownloadDelegate

    /// If `true`, downloads will start immediatly after being created. `true` by default.
    public var startImmediatly = true
    
    /// The underlying `NSURLSession`.
    public let session: URLSession

    /**
     The init() with configuration
     @param(URLSessionConfiguration): the configuration of URLSession
     */
    public init(config: URLSessionConfiguration) {
        self.delegate = DownloadDelegate()
        self.session = URLSession(configuration: config, delegate: self.delegate, delegateQueue: nil)
        self.session.sessionDescription = "GoodDownloadManger session"
    }
    
    /**
     Default `NSURLSessionConfiguration` init.
     */
    public convenience init() {
        let config = URLSessionConfiguration.default
        //config.HTTPMaximumConnectionsPerHost = 1
        self.init(config: config)
    }

    /**
     Private base method to be called by other download methods
     @param(GoodDownload): GoodDownload to start.
     */
    private func downloadWithDownload(download: GoodDownload) -> GoodDownload {
        self.delegate.downloads[download.downloadTask.taskIdentifier] = download
        
        if self.startImmediatly {
            download.downloadTask.resume()
        }
        
        return download
    }
    
    /**
     Start downloading the file at the given URL.
     
     @param(NSURL): url NSURL of the file to download.
     @param(NSURL): directory Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
     @param(String): name Name to give to the file once the download is completed.
     @param(GoodDownloadDelegate): delegate An eventual delegate for this download.
     
     @return: A `GoodDownload` instance.
     */
    public func downloadFileAtURL(url: NSURL, toDirectory directory: NSURL?, withName name: String?, andDelegate delegate: GoodDownloadDelegate?) -> GoodDownload {
        let downloadTask = self.session.downloadTask(with: url as URL)
        let download = GoodDownload(downloadTask: downloadTask, toUserDestinationPath: directory, userFileName: name, delegate: delegate)
        
        return self.downloadWithDownload(download: download)
    }
    
    /**
     Start downloading the file at the given URL.
     
     @param(URL): url NSURL of the file to download.
     @param(NSURL): directory Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
     @param(String): name Name to give to the file once the download is completed.
     @param(progressionHandler): progression A closure executed periodically when a chunk of data is received.
     @param(completionHandler): completion A closure executed when the download has been completed.
     
     @return: A `GoodDownload` instance.
     */
    public func downloadFileAtURL(url: URL, toDirectory directory: NSURL?, withName name: String?, progression : progressionHandler?, completion: completionHandler?) -> GoodDownload {
        let downloadTask = self.session.downloadTask(with: url)
        let download = GoodDownload(downloadTask: downloadTask, toDirectory: directory, fileName: name,
                                    progression:progression, completion:completion)
        
        return self.downloadWithDownload(download: download)
    }
    
    /**
     Resume a download with previously acquired resume data.
     
     -see: `GoodDownload -cancelWithResumeData:` to produce this data.
     
     @param(Data): resumeData Data blob produced by a previous download cancellation.
     @param(NSURL): directory Directory Where to copy the file once the download is completed. If `nil`, the file will be downloaded in the current user temporary directory/
     @param(String): name Name to give to the file once the download is completed.
     @param(GoodDownloadDelegate): delegate An eventual delegate for this download.
     
     @return: A `GoodDownload` instance.
     */
    public func downloadFileWithResumeData(resumeData: Data, toDirectory directory: NSURL?, withName name: String?, andDelegate delegate: GoodDownloadDelegate?) -> GoodDownload {
        let downloadTask = self.session.downloadTask(withResumeData: resumeData)
        let download = GoodDownload(downloadTask: downloadTask, toUserDestinationPath: directory, userFileName: name, delegate: delegate)
        
        return self.downloadWithDownload(download: download)
    }
    
    /**
     Gets the downloads in a given state currently being processed by the instance of `GoodDownloadManager`.
     
     @param(URLSessionTask.State): state The state by which to filter the current downloads.
     
     @return: An `Array` of all current downloads with the given state.
     */
    public func currentDownloadsFilteredByState(state: URLSessionTask.State?) -> [GoodDownload] {
        var downloads = [GoodDownload]()
        
        // TODO: make functional as soon as Dictionary supports reduce/filter.
        for download in self.delegate.downloads.values {
            if state == nil || download.downloadTask.state == state {
                downloads.append(download)
            }
        }
        
        return downloads
    }

}

class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
    var downloads: [Int: GoodDownload] = [:]
    let acceptableStatusCodes = 200...299
    
    func validateResponse(response: HTTPURLResponse) -> Bool {
        return acceptableStatusCodes.contains(response.statusCode)
    }
    
    //methods for URLSessionDownloadDelegate
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didResumeAtOffset fileOffset: Int64,
                    expectedTotalBytes: Int64) {
        print("Resume at offset: \(fileOffset) total expected: \(expectedTotalBytes)")
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let download = self.downloads[downloadTask.taskIdentifier]!
        let progress = totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown ? -1 : Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        download.progress = progress
        
        DispatchQueue.main.async{
            download.delegate?.download(download: download, didProgress: progress, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            download.progression?(progress, totalBytesWritten, totalBytesExpectedToWrite)
            return
        }
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        let download = self.downloads[downloadTask.taskIdentifier]!
        print ("didFinishDownloadingTo: \(location) \n download:\(download)")
        
        var resultingURL: NSURL?
        
        print ("download: destinationURL \(download.destinationURL)")
        do {
            try FileManager.default.replaceItem(at:download.destinationURL, withItemAt: location, backupItemName: download.userFileName, options:[], resultingItemURL: &resultingURL)
            
            download.resultingURL = resultingURL
        }
        catch let error as NSError{
            print("Error: \(error.domain)")
        }
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError sessionError: Error?) {
        
        let download = self.downloads[task.taskIdentifier]!
        var error: NSError? = sessionError as NSError?? ?? download.error
        // Handle possible HTTP errors
        if let response = task.response as? HTTPURLResponse {
            // NSURLErrorDomain errors are not supposed to be reported by this delegate
            // according to https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/NSURLSessionConcepts/NSURLSessionConcepts.html
            // so let's ignore them as they sometimes appear there for now. (But WTF?)
            if !validateResponse(response: response) && (error == nil || error!.domain == NSURLErrorDomain) {
                error = NSError(domain: kGoodDownloadErrorDomain,
                                code: GoodDownloadError.GoodDownloadHTTPError.rawValue,
                                userInfo: [kGoodDownloadErrorDescriptionKey: "Erroneous HTTP status code: \(response.statusCode)",
                                    kGoodDownloadErrorFailingURLKey: task.originalRequest?.url as Any,
                                    kGoodDownloadErrorHTTPStatusKey: response.statusCode])
            }
        }
        // Remove the reference to the download
        self.downloads.removeValue(forKey: task.taskIdentifier)
        
        DispatchQueue.main.async{
            download.delegate?.download(download: download, didFinishWithError: error, atLocation: download.resultingURL)
            download.completion?(error, download.resultingURL)
            return
        }
    }
}








