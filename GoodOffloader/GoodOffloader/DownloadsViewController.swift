//
//  DownloadstViewController.swift
//  GoodOffloader
//
//  Created by Abbott on 4/3/17.
//  Copyright © 2017 Waseda Univ. All rights reserved.
//

import UIKit
import SystemConfiguration
import CoreTelephony

private let kDownloadingCellidentifier = "downloadingCellIdentifier"

extension String {
    func stringByAppendingPathComponent(path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
}

class DownloadsViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, GoodDownloadDelegate {

    
    // Keep track of the current (and probably past soon) downloads
    // This is the tableview's data source
    var downloads = [GoodDownload]()
    
    let manager = GoodDownloadManager.sharedInstance
    let reachability = Reachability()!

    var isFirst: Bool = true

    var downloadData: Data!
    var receivedBytes:Int64 = 0
    var count:Int = 0
    var estimatedRate:Float64 = 0.0
    
    var docPath : String?
    
    let fileURL = NSURL(string: "http://download.thinkbroadband.com/20MB.zip")
    
    @IBOutlet weak var downloadingTableView: UITableView!
    
    var timer:Timer = Timer()

    override func viewDidLoad() {
        super.viewDidLoad()
     //   self.progress.text="press download button to start"
        // Do any additional setup after loading the view, typically from a nib.
        
        let manager = FileManager()
        var paths: NSArray?
        print ("\(NSTemporaryDirectory())")
        paths = manager.subpaths(atPath: NSTemporaryDirectory()) as NSArray?
        print ("Now print sub paths")
        for path in paths!{
            print("\(path)")
        }
        
        self.docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask,true)[0]

        let nib = UINib(nibName: "DownloadTableViewCell", bundle: nil)
        self.downloadingTableView.register(nib, forCellReuseIdentifier: kDownloadingCellidentifier)
        
        self.downloadingTableView.dataSource    = self
        self.downloadingTableView.delegate      = self
        self.downloadingTableView.backgroundColor = UIColor.black
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.handleReachabilityChanged), name: ReachabilityChangedNotification, object:self.reachability)

        do{
            try reachability.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAddDownload" {
            let destinationNC = segue.destination as! UINavigationController
            let destinationVC = destinationNC.topViewController as! AddDownloadViewController
            destinationVC.delegate = self
        }
    }
    func onTimer(){
        
        self.count += 1
        
        self.estimatedRate = Float64(self.receivedBytes) / Float64(self.count*10)
        
        if(self.count < 2 ) {
            self.estimatedRate = Float64(self.receivedBytes) / Float64(self.count*10)
        } else {
            timer.invalidate()
        }
        let alertController = UIAlertController(title: "Estimated Rate"
            , message:"\(self.estimatedRate/1000) kbps"
            , preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
        
    }
    @IBAction func start(_ sender: UIButton) {
        if isFirst {
            //if currentReachabilityStatus == ReachabilityStatus.reachableViaWiFi
            //  {
            self.isFirst = false
            sender.setTitle("resume", for: UIControlState.normal)
            let resumeDataPath = self.docPath!.stringByAppendingPathComponent(path:"file.db")
            let resumeData: NSData? = NSData(contentsOfFile: resumeDataPath)
            let download = self.manager.downloadFileWithResumeData(resumeData: resumeData! as Data,toDirectory:nil, withName:"resume.mp4",andDelegate:self)
            self.downloads.append(download)
            sender.backgroundColor = UIColor.gray
            //   }
        }
        else{
            let download = self.manager.downloadFileWithResumeData(resumeData: self.downloadData,toDirectory:nil, withName:"resume.mp4",andDelegate:self)
            self.downloads.append(download)
            sender.backgroundColor = UIColor.white
        }
    }
    @IBAction func cancel(_ sender: UIButton) {
        
        /*
         _fileData = resumeData;
         _task = nil;
         [resumeData writeToFile:dataPath atomically:YES];
         [self getDownloadFile];
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
         //做完保存操作之后让他继续下载
         if (_fileData)
         {
         _task = [self.backgroundURLSession downloadTaskWithResumeData:_fileData];
         [_task resume];
         }
         });
         */
        
        self.downloads[0].cancelWithResumeData(completionHandler:{(resumeData) in
            if ( resumeData  != nil )
            {
                self.downloadData = resumeData
                print ("resumeData:\(resumeData)")
            }
        })
        self.downloads.remove(at:0)
        let dataPath = self.docPath!.stringByAppendingPathComponent(path:"file.db")
        if ( self.downloadData != nil ){
            print ("downloadData: \(self.downloadData!)")        }
        print ("data path:\(dataPath)")
        do {
            if (self.downloadData != nil ){
                try NSData(data: self.downloadData).write(toFile:dataPath)
            }
        }
        catch let error as NSError{
            print("Error:\(error.domain)")
        }
    }
    
    private func getDownloadFromButtonPress(sender: UIButton, event: UIEvent) -> (download: GoodDownload, indexPath: IndexPath) {
        let touch = (event.touches(for: sender)?.first)! as UITouch
        let location = touch.location(in: self.downloadingTableView)
        let indexPath = self.downloadingTableView.indexPathForRow(at: location)
        
        return (self.downloads[indexPath!.row], indexPath!)
    }
    
    //Handler for network status change
    func handleReachabilityChanged(notification:NSNotification?)
    {
        // notification.object will be a 'Reachability' object that you can query
        // for the network status.
        let alertController = UIAlertController(title: "Network Status"
            , message:"WiFi: \(self.reachability.isReachableViaWiFi),  Cellular: \(reachability.isReachableViaWWAN)"
            , preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertController.addAction(defaultAction)
        present(alertController, animated: true, completion: nil)
/* 
          // This code juged what the radio access network technology is being used
        if reachability.isReachableViaWWAN {
            let telInfo = CTTelephonyNetworkInfo()
            self.display.text = telInfo.currentRadioAccessTechnology! + "|"
                + (telInfo.subscriberCellularProvider?.carrierName)!
            if telInfo.currentRadioAccessTechnology == CTRadioAccessTechnologyLTE {
                // Device has a LTE connection
                print ("Network is LTE ")
            }
        }
 */
    }
    
    func addDownloadWithURL(url: NSURL?, name: String?) {
        let download = self.manager.downloadFileAtURL(url: url!, toDirectory: nil, withName: name, andDelegate: self)

        // Stop all the other timer
        timer.invalidate()
        
        // execute the handler for every 10 seconds
        timer = Timer.scheduledTimer(timeInterval: 10, target:self, selector:#selector(DownloadsViewController.onTimer), userInfo:nil, repeats:true)

        self.downloads.append(download)
        print("DownlaodsViewController/addDownloadWithURL url:\(url)")
        let insertIndexPath = IndexPath(row: self.downloads.count - 1, section: 0)
        self.downloadingTableView.insertRows(at: [insertIndexPath], with: UITableViewRowAnimation.automatic)
        

    }

    func didPressPauseButton(sender: UIButton!, event: UIEvent) {
        let e = self.getDownloadFromButtonPress(sender: sender, event: event)
        
        if e.download.downloadTask.state == URLSessionTask.State.running {
            e.download.suspend()
        } else {
            e.download.resume()
        }
        
        self.downloadingTableView.reloadRows(at: [e.indexPath], with: UITableViewRowAnimation.none)
    }
    
    func didPressCancelButton(sender: UIButton!, event: UIEvent) {
        let e = self.getDownloadFromButtonPress(sender: sender, event: event)
        
        e.download.cancel()
    }

    
    // For UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: kDownloadingCellidentifier) as! DownloadTableViewCell
        
        let download: GoodDownload = self.downloads[indexPath.row]
        if let fileName = download.fileName{
            cell.labelFileName.text = fileName
        }
        else{
            cell.labelFileName.text = "..."
        }
        
        if download.downloadTask.state == URLSessionTask.State.running {
            cell.buttonPause.setTitle("Pause", for: UIControlState.normal)
        } else if download.downloadTask.state == URLSessionTask.State.suspended {
            cell.buttonPause.setTitle("Resume", for: UIControlState.normal)
        }
        
        cell.progress = download.progress
        cell.labelDownload.text = download.downloadTask.originalRequest?.url?.absoluteString
        cell.buttonPause.addTarget(self, action: #selector(self.didPressPauseButton(sender:event:)),
                                   for: UIControlEvents.touchUpInside)
        cell.buttonCancel.addTarget(self, action: #selector(self.didPressCancelButton(sender:event:)),
                                    for: UIControlEvents.touchUpInside)
        
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int{
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.downloads.count
    }
    
    // For UITableViewDelegate
    func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat{
        return 90
    }
    
    // For GoodDownloadDelegate
    func download(download: GoodDownload, didProgress progress: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        self.receivedBytes = totalBytesWritten
        let downloads: NSArray = self.downloads as NSArray
        let index = downloads.index(of: download)
        let updateIndexPath = IndexPath(row: index, section: 0)
        
        let cell = self.downloadingTableView.cellForRow(at: updateIndexPath) as! DownloadTableViewCell
        cell.progress = progress
    }
    
    func download(download: GoodDownload, didFinishWithError: NSError?, atLocation location: NSURL?) {
        
        timer.invalidate()
        
        let downloads: NSArray = self.downloads as NSArray
        let index = downloads.index(of: download)
        self.downloads.remove(at: index)
        
        let deleteIndexPath = IndexPath(row: index, section: 0)
        self.downloadingTableView.deleteRows(at: [deleteIndexPath], with: UITableViewRowAnimation.automatic)
    }

}
