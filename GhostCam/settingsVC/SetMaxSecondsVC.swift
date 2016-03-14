//
//  SetMaxSecondsVC.swift
//  GhostCam
//
//  Created by Leyun Song on 16/1/25.
//  Copyright © 2016年 Leyun Song. All rights reserved.
//

import UIKit

class SetMaxSecondsVC: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var selectMaxSecondsPickView: UIPickerView!
    
    var userSettings:Settings = Settings()
    let settingsDefaults = NSUserDefaults.standardUserDefaults()
    
    var secs = [1,3,5,7,10,20,30,60]
    var selectedSec :Int?
    var selectedRow = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectMaxSecondsPickView.delegate = self
        self.selectMaxSecondsPickView.dataSource = self
        self.navigationItem.title = "Max Record Time"
        self.tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.rightBarButtonItem?.enabled = false
        selectedSec = userSettings.maxSeconds
        switch userSettings.maxSeconds {
        case 1:
            selectedRow = 0
        case 3:
            selectedRow = 1
        case 5:
            selectedRow = 2
        case 7:
            selectedRow = 3
        case 10:
            selectedRow = 4
        case 20:
            selectedRow = 5
        case 30:
            selectedRow = 6
        case 60:
            selectedRow = 7
        default:
            selectedRow = 0
        }
        self.selectMaxSecondsPickView.selectRow(selectedRow, inComponent: 0, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.tabBarController?.tabBar.hidden = false
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UIPickerView Protocol
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int)->Int {
        return secs.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(secs[row])
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            selectedSec = 1
        case 1:
            selectedSec = 3
        case 2:
            selectedSec = 5
        case 3:
            selectedSec = 7
        case 4:
            selectedSec = 10
        case 5:
            selectedSec = 20
        case 6:
            selectedSec = 30
        case 7:
            selectedSec = 60
        default:
            selectedSec = 1
        }
        self.navigationItem.rightBarButtonItem?.enabled = true
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        let pickerlabel = UILabel(frame: CGRect(x: 20.0, y: 0, width: 300, height: 90) )
        pickerlabel.textAlignment = NSTextAlignment.Natural
        pickerlabel.text = String(secs[row])
        pickerlabel.font = UIFont.systemFontOfSize(24)
        return pickerlabel
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "unwindToSettings" {
            userSettings.maxSeconds = selectedSec!
            settingsDefaults.setInteger(userSettings.maxSeconds, forKey: "maxSecondsKey")
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
