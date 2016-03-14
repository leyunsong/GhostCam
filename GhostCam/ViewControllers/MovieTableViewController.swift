//
//  MovieTableViewController.swift
//  GhostCam
//
//  Created by Leyun Song on 16/1/3.
//  Copyright © 2016年 Leyun Song. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation


class MovieTableViewController: UITableViewController, AVPlayerViewControllerDelegate {
    
    // MARK: Properties
    var userSettings = Settings()
    var movies = [Movie]()
    var dataQueue : dispatch_queue_t?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataQueue = dispatch_queue_create( "data queue", DISPATCH_QUEUE_SERIAL)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Use the edit button item provided by the table view controller.
        navigationItem.leftBarButtonItem = editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        if let savedMovies = loadMovies() {
            self.movies = savedMovies
        } else {
            showMessage("No movies found.")
        }
        self.tableView.reloadData()
        
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if movies.count==0 {
            // Show a "not-data" label if no movies found.
            let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))
            noDataLabel.backgroundColor = UIColor.groupTableViewBackgroundColor()
            noDataLabel.text = "No data is currently available. Tap CAM to capture a new movie clip."
            noDataLabel.textColor = UIColor.darkTextColor()
            noDataLabel.numberOfLines = 0;
            noDataLabel.textAlignment = NSTextAlignment.Center
            noDataLabel.sizeToFit()
            
            self.tableView.backgroundView = noDataLabel
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            self.navigationItem.leftBarButtonItem?.enabled = false
        } else {
            self.tableView.backgroundView = nil
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            self.navigationItem.leftBarButtonItem?.enabled = true
        }
        return 1
        
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        
        // Config the tabelview cell and load data
        
            let cellIdentifier = "MovieTableViewCell"
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! MovieTableViewCell
            let movie = movies[indexPath.row]
            
            cell.nameLabel.text = movie.name
            cell.Preview.image = movie.preview
            
            let date = NSDate.init(timeIntervalSince1970: movie.duration.seconds)
            let formatter = NSDateFormatter()
            formatter.dateFormat = "mm:ss"
            formatter.timeZone = NSTimeZone.init(abbreviation: "UTC")
            let time = formatter.stringFromDate(date)
            cell.durationLabel.text = time
            
            cell.filePathLabel.text = movie.filePath
            cell.filePathLabel.numberOfLines = 0
            cell.filePathLabel.sizeToFit()
        
        do {
           let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(movie.filePath) as NSDictionary
            let fileSizeByte = fileAttributes.fileSize()
            let fileSizeString = NSByteCountFormatter.stringFromByteCount(Int64(fileSizeByte), countStyle: .File)
            cell.fileSizeLabel.text = fileSizeString
        } catch _ as NSError {
            //print("Movie file Attributes Unavailable")
        }
        
            
            return cell
        
    }
    
    // MARK: NSCoding
    func saveMovies() {
        
        dispatch_async(dataQueue!, {
            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.movies, toFile: Movie.ArchiveURL.path!)
            if !isSuccessfulSave {
                print("Failed to save movies...")
            }
        })
        
        
    }
    
    func loadMovies() -> [Movie]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(Movie.ArchiveURL.path!) as? [Movie]
    }
    
    func showMessage(message:NSString){
        var messageWindow = UIWindow()
        messageWindow = UIApplication.sharedApplication().keyWindow!
        let showView = UIView()
        showView.backgroundColor = UIColor.blackColor()
        showView.frame = CGRectMake(1, 1, 1, 1)
        showView.alpha = 1.0
        showView.layer.cornerRadius = 5.0
        showView.layer.masksToBounds = true
        messageWindow.addSubview(showView)
        
        let font = UIFont.systemFontOfSize(17)
        let Label = UILabel()
        var labelSize = CGRect()
        
        labelSize = message.boundingRectWithSize(CGSizeMake(200,3000), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:font], context: nil)
        Label.frame = CGRectMake(10, 5, labelSize.size.width, labelSize.size.height)
        Label.text = message as String
        Label.textColor = UIColor.whiteColor()
        Label.backgroundColor = UIColor.clearColor()
        Label.textAlignment = NSTextAlignment.Center
        Label.font = UIFont.boldSystemFontOfSize(15)
        showView.addSubview(Label)
        
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        showView.frame = CGRectMake((screenWidth - labelSize.size.width-20)/2, (screenHeight-labelSize.height)/2, labelSize.size.width+20, labelSize.size.height+10)
        
        UIView.animateWithDuration(1.5, animations: {
            showView.alpha = 0
            }, completion: {
                (finished) in showView.removeFromSuperview()
        })
        
    }
    
    
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if movies.count==0 {
            return false
        } else {
            return true
        }
    }


    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            do {
                let filename = self.movies[indexPath.row].name
                let fileManager = NSFileManager()
                try fileManager.removeItemAtPath(Movie.DocumentsDirectory.path! + "/" + filename + ".mov")
            } catch _ as NSError {
                showMessage("Failed to delete movie file")
            }
            
            self.movies.removeAtIndex(indexPath.row)
            saveMovies()
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }


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

    
    // MARK: - Navigation
    @IBAction func unwindToMovieTableView(sender:UIStoryboardSegue) {
        
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // config the segue to custom playerViewController
        if segue.identifier == "segueToPlayer" {
            let playerViewController = segue.destinationViewController as! PlayerViewController
            
            if let selectedMovieCell = sender as? MovieTableViewCell {
                let indexPath = tableView.indexPathForCell(selectedMovieCell)!
                let selectedMovie = movies[indexPath.row]
                let selectedMovieURL = NSURL(fileURLWithPath: (Movie.DocumentsDirectory.path! + "/" + selectedMovie.name + ".mov"))
              playerViewController.movieURL = selectedMovieURL
            }
        }
        
        
        //Add a segueToAVPlayer to a AVPlayerViewController Object to Storyboard to enable system player playing
        if segue.identifier == "segueToAVPlayer" {
            let avplayerViewController = segue.destinationViewController as! AVPlayerViewController
            // Get the cell that generated this segue.
            if let selectedMovieCell = sender as? MovieTableViewCell {
                let indexPath = tableView.indexPathForCell(selectedMovieCell)!
                let selectedMovie = movies[indexPath.row]
                let selectedMovieURL = NSURL(fileURLWithPath: (Movie.DocumentsDirectory.path! + "/" + selectedMovie.name + ".mov"))
                
                avplayerViewController.player = AVPlayer(URL: selectedMovieURL)
                userSettings = Settings()
                avplayerViewController.player?.play()
                
                
            }
            
        }
        
    }
    
    

}
