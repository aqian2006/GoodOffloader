//
//  GoodDownload.swift
//  GoodOffload
//
//  Created by Abbott on 4/3/17.
//  Copyright © 2017 Waseda Univ. All rights reserved.
//

import Foundation

public typealias progressionHandler = ((Float, Int64, Int64) -> Void)!
public typealias completionHandler = ((NSError?, NSURL?) -> Void)!


public class GoodDownload{
    
    // Download task, init
    public let downloadTask: URLSessionDownloadTask
    
    // Delegate to get notificed of events
    public weak var delegate: GoodDownloadDelegate?
    
    // init
    public var progression: progressionHandler?
    
    /// init, An optional completion closure executed when a download was completed by the download task.
    public var completion: completionHandler?
    
    /// An optional file name set by the user.
    public let userFileName: String?
    
    /// An optional destination path for the file. If nil, the file will be downloaded in the current user temporary directory.
    public let userDestinationPath: NSURL?
    
    /// Will contain an error if the downloaded file couldn't be moved to its final destination.
    var error: NSError?
    
    /// Current progress of the download, a value between 0 and 1. 0 means nothing was received and 1 means the download is completed.
    public var progress: Float = 0
    
    /// If the moving of the file after downloading was successful, will contain the `NSURL` pointing to the final file.
    public var resultingURL: NSURL?
    
    /// A computed property to get the filename of the downloaded file.
    public var fileName: String? {
    //    return self.userFileName??;self.downloadTask.response?.suggestedFilename
        return self.downloadTask.response?.suggestedFilename
    }
    
    public var destinationURL: URL {
    
        let destinationPath = self.userDestinationPath ?? NSURL(fileURLWithPath: NSTemporaryDirectory())
//        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)
//        let destinationPath = self.userDestinationPath ?? NSURL(fileURLWithPath: "file:///private" + docPath[0])
        //let destinationPath = URL (string: "file:///private" + docPath[0])
//        return NSURL(string: self.fileName!, relativeTo: destinationPath as URL)!.standardizingPath!
          return NSURL(string: self.userFileName!, relativeTo: destinationPath as URL)!.standardizingPath!
    }
    /**
     Initialize a new download assuming the `NSURLSessionDownloadTask` was already created.
     
     @param(URLSessionDownloadTask): downloadTask The underlying download task for this download.
     @param(NSURL): directory The directory where to move the downloaded file once completed.
     @param(String): fileName The preferred file name once the download is completed.
     @param(GoodDownloadDelegate): delegate An optional delegate for this download.
     */
    
    init(downloadTask: URLSessionDownloadTask, toUserDestinationPath destinationPath: NSURL?,userFileName:String?, delegate: GoodDownloadDelegate?){
        self.downloadTask           = downloadTask
        self.userDestinationPath    = destinationPath
        self.userFileName           = userFileName
        self.delegate               = delegate
    }
    
    /**
     
     */
    convenience init(downloadTask: URLSessionDownloadTask, toDirectory directory: NSURL?, fileName: String?, progression: progressionHandler?, completion:completionHandler?) {
        self.init(downloadTask: downloadTask, toUserDestinationPath: directory, userFileName: fileName, delegate: nil)
        self.progression = progression
        self.completion  = completion
    }

    public func cancel(){
        self.downloadTask.cancel()
    }
    
    public func suspend(){
        self.downloadTask.suspend()
    }

    /**
     Resume a previously suspended download. Can also start a download if not already downloading.
     
     :see: `NSURLSessionDownloadTask -resume`
     */
    public func resume(){
        self.downloadTask.resume()
    }

    /**
     Cancel a download and produce resume data. If stored, this data can allow resuming the download at its previous state.
     
     -see: `GoodDownloadManager -downloadFileWithResumeData`
     -see: `URLSessionDownloadTask -cancelByProducingResumeData`
     
     @param: completionHandler A completion handler that is called when the download has been successfully canceled. If the download is resumable, the completion handler is provided with a resumeData object.
     */
    public func cancelWithResumeData(completionHandler: @escaping (Data?)->Void){
        self.downloadTask.cancel(byProducingResumeData: completionHandler)
    }
}

public protocol GoodDownloadDelegate: class{
    
    /**
     Periodically informs the delegate that a chunk of data has been received (similar to `NSURLSession -URLSession:dataTask:didReceiveData:`).
     
     - see: `NSURLSession -URLSession:dataTask:didReceiveData:`
     
     @param(GoodDownload): download The download that received a chunk of data.
     @param(Float): progress The current progress of the download, between 0 and 1. 0 means nothing was received and 1 means the download is completed.
     @param(Int64): totalBytesWritten The total number of bytes the download has currently written to the disk.
     @param(Int64): totalBytesExpectedToWrite The total number of bytes the download will write to the disk once completed.
     */
    func download(download: GoodDownload, didProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)

    /**
     Informs the delegate that the download was completed (similar to `NSURLSession -URLSession:task:didCompleteWithError:`).
     
     -see: `NSURLSession -URLSession:task:didCompleteWithError:`
     
     @param(GoodDownload): download The download that received a chunk of data.
     @param(NSError): error An eventual error. If `nil`, consider the download as being successful.
     @param(NSURL): location The location where the downloaded file can be found.
     */
    func download(download: GoodDownload, didFinishWithError error: NSError?, atLocation location: NSURL?)
}

extension GoodDownload: CustomStringConvertible{
    public var description:String{
        var parts: [String] = []
        var state: String
        
        switch self.downloadTask.state{
        case .running:   state = "running"
        case .completed: state = "completed"
        case .canceling: state = "canceling"
        case .suspended: state = "suspended"
        }
        parts.append("GoodDownload")
        parts.append("URL: \(self.downloadTask.originalRequest?.url)")
        parts.append("Download task state: \(state)")
        parts.append("destinationPath: \(self.userDestinationPath)")
        parts.append("fileName: \(self.fileName)")
        
        return parts.joined(separator: "|")
    }
    
}










