//
//  SettingsTableViewController.swift
//  GhostCam
//
//  Created by Leyun Song on 16/1/18.
//  Copyright © 2016年 Leyun Song. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var maskTapSwitch: UISwitch!
    @IBOutlet weak var speedDetail: UILabel!
    @IBOutlet weak var fpsDetail: UILabel!
    @IBOutlet weak var maxSecondsDetail: UILabel!
    
    
    let settingsDefaults = NSUserDefaults.standardUserDefaults()
    var userSettings = Settings()
    
    
    @IBAction func maskSwitch(sender: UISwitch) {
        settingsDefaults.setBool(maskTapSwitch.on, forKey: "maskKey")
        userSettings = Settings()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        updateTableViewDetails()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTableViewDetails() {
        userSettings = Settings()
        maskTapSwitch.setOn(userSettings.mask, animated: true)

        switch userSettings.frameRate {
        case 1:
            fpsDetail.text = "30 fps"
        case 2:
            fpsDetail.text = "60 fps"
        case 3:
            fpsDetail.text = "120 fps"
        case 4:
            fpsDetail.text = "240 fps"
        default:
            fpsDetail.text = "Default (30fps)"
        }
        
        maxSecondsDetail.text = "\(userSettings.maxSeconds) sec"
    }
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "setFPS" {
            let setFPSViewController = segue.destinationViewController as! SetFpsTVC
            setFPSViewController.userSettings.frameRate = self.userSettings.frameRate
        } else if segue.identifier == "setMaxSeconds" {
            let setMaxSecondsViewController = segue.destinationViewController as! SetMaxSecondsVC
            setMaxSecondsViewController.userSettings.maxSeconds = self.userSettings.maxSeconds
            
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    @IBAction func unwindToSettings(sender:UIStoryboardSegue) {
        userSettings = Settings()
        maxSecondsDetail.text = "\(userSettings.maxSeconds) s"
    }
    
    /*
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 1:
            return 3
        case 2:
            return 1
        default:
            return 0
        }
    }
    */
}

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation

    */

