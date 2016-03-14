//
//  SetFpsTVC.swift
//  GhostCam
//
//  Created by Leyun Song on 16/1/19.
//  Copyright © 2016年 Leyun Song. All rights reserved.
//

import UIKit

class SetFpsTVC: UITableViewController {
    
    @IBOutlet weak var fps30: UITableViewCell!
    @IBOutlet weak var fps60: UITableViewCell!
    @IBOutlet weak var fps120: UITableViewCell!
    @IBOutlet weak var fps240: UITableViewCell!
    
    
    
    var userSettings:Settings = Settings()
    let settingsDefaults = NSUserDefaults.standardUserDefaults()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.hidden = true
        self.navigationItem.title = "Recording FPS"
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.tabBarController?.tabBar.hidden = false
    }

    override func viewWillAppear(animated: Bool) {
        updateSelection()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        settingsDefaults.setInteger(indexPath.row+1, forKey: "frameRateKey")
        deselect()
        updateSelection()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    func deselect() {
        //Deselection Checkmark
        switch userSettings.frameRate {
        case 1:
            fps30.accessoryType = UITableViewCellAccessoryType.None
        case 2:
            fps60.accessoryType = UITableViewCellAccessoryType.None
        case 3:
            fps120.accessoryType = UITableViewCellAccessoryType.None
        case 4:
            fps240.accessoryType = UITableViewCellAccessoryType.None
        default:
            break
        }
    }
    
    func updateSelection() {
        userSettings = Settings()
        switch userSettings.frameRate {
        case 1:
            fps30.accessoryType = UITableViewCellAccessoryType.Checkmark
        case 2:
            fps60.accessoryType = UITableViewCellAccessoryType.Checkmark
        case 3:
            fps120.accessoryType = UITableViewCellAccessoryType.Checkmark
        case 4:
            fps240.accessoryType = UITableViewCellAccessoryType.Checkmark
        default:
            break
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 4
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
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
