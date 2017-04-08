//
//  DownloadTableViewController.swift
//  GoodOffloader
//
//  Created by Abbott on 4/6/17.
//  Copyright © 2017 Waseda Univ. All rights reserved.
//

import UIKit

private let kDownloadCellidentifier = "downloadCellIdentifier"

class DownloadTableViewController: UITableViewController {

  //  @IBOutlet weak var downloadsTableView: UITableView!
    @IBOutlet weak var downloadsTableView: UITableView!

    var downloadedFiles = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()

        let nib = UINib(nibName: "DownloadTableViewCell", bundle: nil)
        self.downloadsTableView.register(nib, forCellReuseIdentifier: kDownloadCellidentifier)
        
        let manager = FileManager()

        print ("\(NSTemporaryDirectory())")
        
        self.downloadedFiles = manager.subpaths(atPath: NSTemporaryDirectory())!

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

        return self.downloadedFiles.count
    }
    
    override func tableView(_ tableView: UITableView,heightForRowAt indexPath: IndexPath) -> CGFloat{
        //    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 30
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Configure the cell...
        let cell = tableView.dequeueReusableCell(withIdentifier: kDownloadCellidentifier) as! DownloadTableViewCell
        
        cell.buttonPause.isHidden = true
        cell.buttonCancel.isHidden = true
        cell.progressView.isHidden = true
        cell.labelDownload.isHidden = true
        
        cell.labelFileName.text = "\(indexPath.row+1):" + self.downloadedFiles[indexPath.row]
        
        return cell
    }
}
