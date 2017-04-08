//
//  AddDownloadViewController.swift
//  GoodOffloader
//
//  Created by Abbott on 4/7/17.
//  Copyright © 2017 Waseda Univ. All rights reserved.
//

import UIKit

class AddDownloadViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    weak var delegate: DownloadsViewController?
    var pickerData: [String] = [String]()
    
    @IBOutlet weak var urlPickerView: UIPickerView!
    @IBOutlet weak var fileURL: UITextField!
    @IBOutlet weak var fileName: UITextField!
    @IBOutlet weak var deadLine: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.urlPickerView.dataSource   = self
        self.urlPickerView.delegate     = self

        self.urlPickerView.setValue(UIColor.white, forKey: "textColor")
        self.datePicker.minimumDate = Date()
        self.pickerData = ["http://download.thinkbroadband.com/5MB.zip"
            , "http://download.thinkbroadband.com/10MB.zip"
            , "http://download.thinkbroadband.com/20MB.zip"
            , "http://download.thinkbroadband.com/50MB.zip"
            , "http://download.thinkbroadband.com/100MB.zip"
            , "http://download.thinkbroadband.com/200MB.zip"]
 
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
   }
    
    // The number of columns of data
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = view as! UILabel!
        if label == nil {
            label = UILabel()
        }
        
        let data = pickerData[row]
        let title = NSAttributedString(string: data, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 15.0, weight: UIFontWeightRegular)])
        label?.attributedText = title
        label?.textAlignment = .left
        return label!

     //   return self.pickerData[row]
    }
    
    // Catpure the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This method is triggered whenever the user makes a change to the picker selection.
        // The parameter named row and component represents what was selected.
        self.fileURL.text   = self.pickerData[row]
        self.fileName.text  = (self.pickerData[row] as NSString).lastPathComponent
    }
    
    @IBAction func onDatePickerValueChanged(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.medium
        self.deadLine.text = dateFormatter.string(from: (sender.date))
    }
    @IBAction func onAddDownload(_ sender: UIBarButtonItem) {

        let downloadURL = NSURL(string: self.fileURL.text!)
        self.delegate?.addDownloadWithURL(url: downloadURL, name: self.fileName.text)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDatePicker(_ sender: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.medium
        dateFormatter.timeStyle = DateFormatter.Style.medium
        self.deadLine.text = dateFormatter.string(from: (sender.date))
    }
}
