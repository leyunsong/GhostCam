//
//  AVPlayerViewController.swift
//  GhostCam
//
//  Created by Leyun Song on 16/2/1.
//  Copyright © 2016年 Leyun Song. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

class PlayerViewController: UIViewController {

    @IBOutlet weak var viewForPlayerLayer: UIView!
    @IBOutlet weak var TopOverlay: UIView!
    @IBOutlet weak var BottomOverlay: UIView!
    @IBOutlet weak var timeHeader: UILabel!
    @IBOutlet weak var timeFooter: UILabel!
    
    
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var loopButton: UIButton!
    @IBOutlet weak var speedDownButton: UIButton!
    @IBOutlet weak var speedUpButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBOutlet weak var UILayerView: UIView!
    @IBOutlet weak var controls: UIStackView!
    
    var movieURL:NSURL!
    let playerLayer = AVPlayerLayer()
    var player: AVPlayer {
        return playerLayer.player!
    }
    
    var UIHidden = false
    var isLooping = false
    var isPlaying = false
    var isSeeking = false
    var TimeObserver: AnyObject?
    var restoreRateAfterSlide:Float?
    
    // MARK: - Initialization
    func initPlayerLayer(resourceURL:NSURL) {
        playerLayer.frame = UIScreen.mainScreen().bounds
        let player = AVPlayer(URL: resourceURL)
        player.actionAtItemEnd = .None
        playerLayer.player = player
        
    }
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initPlayerLayer(movieURL)
        initSliderTimer()
        syncSlider()
        syncTimeHeader()
        syncTimeFooter()
        viewForPlayerLayer.layer.addSublayer(playerLayer)
       
        self.playPauseButton.setImage(UIImage(named: "PauseFilled"), forState: .Highlighted)
        self.playPauseButton.setImage(UIImage(named: "PlayFilled"), forState: .Highlighted)
        self.speedUpButton.setImage(UIImage(named: "StepForwardFilled"), forState: .Highlighted)
        self.speedDownButton.setImage(UIImage(named: "StepBackwardFilled"), forState: .Highlighted)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PlayerViewController.playerDidReachEndNotificationHandler(_:)), name: "AVPlayerItemDidPlayToEndTimeNotification", object: player.currentItem)
        // Do any additional setup after loading the view.
    }
    
    
    
    
    override func viewWillAppear(animated: Bool) {
        // BlurOverlay
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            self.TopOverlay.backgroundColor = UIColor.clearColor()
            self.BottomOverlay.backgroundColor = UIColor.clearColor()
            
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            blurEffectView.frame = self.TopOverlay.bounds
            self.TopOverlay.addSubview(blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
            
            let bottomblurEffectView = UIVisualEffectView(effect: blurEffect)
            
            bottomblurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            bottomblurEffectView.frame = self.BottomOverlay.bounds
            self.BottomOverlay.addSubview(bottomblurEffectView)
            
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Slider Functions
    func initSliderTimer() {
        var interval = 0.1
        let playerDuration = self.player.currentItem!.duration
        if (CMTIME_IS_INVALID(playerDuration)) {
            return
        }
        let duration = CMTimeGetSeconds(playerDuration)
        if (isfinite(duration)) {
            let width = CGRectGetWidth(self.progress.bounds)
            interval = 0.1 * Float64(duration) / Float64(width)
        }
        
        TimeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(interval, Int32(NSEC_PER_SEC)), queue: nil, usingBlock: {_ in
            self.syncSlider()
            self.syncTimeHeader()
        })
    }
    
    func syncSlider() {
        let playerDuration = self.player.currentItem!.duration
        if (CMTIME_IS_INVALID(playerDuration)) {
            return
        }
        let duration = CMTimeGetSeconds(playerDuration)
        if (isfinite(duration)) {
            let minValue = self.progress.minimumValue
            let maxValue = self.progress.maximumValue
            let time = CMTimeGetSeconds(self.player.currentTime())
            self.progress.value = (maxValue - minValue) * Float(time) / Float(duration) + minValue
        }
    }
    
    @IBAction func beginSliding(sender: UISlider) {
        restoreRateAfterSlide = self.player.rate
        self.player.rate = 0
        self.removePlayerTimeObserver()
    }
    
    
    @IBAction func Slide(sender: UISlider) {
        if !isSeeking {
            isSeeking = true
            let slider = sender
            let playerDuration = self.player.currentItem!.duration
            if (CMTIME_IS_INVALID(playerDuration)) {
                return
            }
            let duration = CMTimeGetSeconds(playerDuration)
            if (isfinite(duration)) {
                let minValue = self.progress.minimumValue
                let maxValue = self.progress.maximumValue
                let value = slider.value
                let time = Float(duration) * (value - minValue) / (maxValue - minValue)
                self.player.seekToTime(CMTimeMakeWithSeconds(Float64(time), Int32(NSEC_PER_SEC)), completionHandler: {
                _ in
                    self.isSeeking = false
                })
            }
            self.syncTimeHeader()
        }
    }
    
    @IBAction func endSliding(sender: UISlider) {
        
            let playerDuration = self.player.currentItem!.duration
            if (CMTIME_IS_INVALID(playerDuration)) {
                return
            }
            let duration = CMTimeGetSeconds(playerDuration)
            if (isfinite(duration)) {
                
                let width = CGRectGetWidth(self.progress.bounds)
                
                let tolerance = 0.1 * duration / Double(width);
                TimeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMakeWithSeconds(tolerance, Int32(NSEC_PER_SEC)), queue: nil, usingBlock: {_ in
                    self.syncSlider()
                    self.syncTimeHeader()
                })
            }
        
        
        if let Rate = restoreRateAfterSlide {
            self.player.rate = Rate
            restoreRateAfterSlide = 0.0
        }
        
        
    }
    
    //Tap GestureRecognizer
    @IBAction func videoTapped(sender: UITapGestureRecognizer) {
        switch UIHidden {
        case false:
            self.UIHidden = true
            UIView.animateWithDuration(0.2, animations: {
                self.TopOverlay.alpha = 0
                self.BottomOverlay.alpha = 0
                self.progress.alpha = 0
                self.timeHeader.alpha = 0
                self.timeFooter.alpha = 0
                self.controls.alpha = 0
                self.exitButton.alpha = 0
                self.loopButton.alpha = 0
                }, completion: {
            Faded in
                self.TopOverlay.hidden = true
                self.BottomOverlay.hidden = true
                self.progress.hidden = true
                self.timeHeader.hidden = true
                self.timeFooter.hidden = true
                self.controls.hidden = true
                self.exitButton.hidden = true
                self.loopButton.hidden = true
            })
            
        case true:
            self.TopOverlay.hidden = false
            self.BottomOverlay.hidden = false
            self.progress.hidden = false
            self.timeHeader.hidden = false
            self.timeFooter.hidden = false
            self.controls.hidden = false
            self.exitButton.hidden = false
            self.loopButton.hidden = false
            UIView.animateWithDuration(0.2, animations: {
                self.TopOverlay.alpha = 1
                self.BottomOverlay.alpha = 1
                self.progress.alpha = 1
                self.timeHeader.alpha = 1
                self.timeFooter.alpha = 1
                self.controls.alpha = 1
                self.exitButton.alpha = 1
                self.loopButton.alpha = 1
                }, completion: {
            Showed in
                    self.UIHidden = false
            })
        }
        
    }
    
    
    
    
    // MARK: - Buttons Actions
    @IBAction func playPause(sender: UIButton) {
        guard !isSeeking else {return}
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
        updatePlayPauseButton()
    }
    @IBAction func speedUp(sender: UIButton) {
        player.pause()
        isPlaying = false
        updatePlayPauseButton()
        
        let item = player.currentItem
        item?.stepByCount(1)
        
/* Used as SpeedUp PlayRate
        guard !isSeeking else {return}
        switch player.rate {
        case 0.25:
            player.rate = 0.5
        case 0.5:
            player.rate = 1
        case 1:
            player.rate = 2
        case 2:
            player.rate = 4
        case 4:
            player.rate = 4
        default:
            player.rate = 1
        }
        print(player.rate)
*/
    }
    @IBAction func speedDown(sender: UIButton) {
        player.pause()
        isPlaying = false
        updatePlayPauseButton()
        
        let item = player.currentItem
        item?.stepByCount(-1)
        
/* Used as SpeedDown PlayRate
        guard !isSeeking else {return}
        switch player.rate {
        case 0.25:
            player.rate = 0.25
        case 0.5:
            player.rate = 0.25
        case 1:
            player.rate = 0.5
        case 2:
            player.rate = 1
        case 4:
            player.rate = 2
        default:
            player.rate = 1
        }
        print(player.rate)
*/
    }
    @IBAction func loop(sender: UIButton) {
        guard !isSeeking else {return}
        isLooping = !isLooping
        updateLoopButton()
    }
    
    // MARK: - UI Updates Funcs
    func syncTimeFooter() {
        let Duration = player.currentItem?.asset.duration.seconds
        let date = NSDate.init(timeIntervalSince1970: Duration!)
        let formatter = NSDateFormatter()
        formatter.dateFormat = "mm:ss"
        formatter.timeZone = NSTimeZone.init(abbreviation: "UTC")
        let durationTime = formatter.stringFromDate(date)
        self.timeFooter.text = durationTime
    }
    
    func syncTimeHeader() {
        let time = CMTimeGetSeconds(self.player.currentTime())
        let date = NSDate.init(timeIntervalSince1970: time)
        let formatter = NSDateFormatter()
        formatter.dateFormat = "mm:ss"
        formatter.timeZone = NSTimeZone.init(abbreviation: "UTC")
        let currentTime = formatter.stringFromDate(date)
        self.timeHeader.text = currentTime
    }

    
    func updatePlayPauseButton () {
        if isPlaying {
            self.playPauseButton.setImage(UIImage(named: "Pause"), forState: .Normal)
            
        } else {
            self.playPauseButton.setImage(UIImage(named: "Play"), forState: .Normal)
            
        }
    }
    
    func updateLoopButton () {
        if isLooping {
            self.loopButton.setImage(UIImage(named: "Loop"), forState: .Normal)
        } else {
            self.loopButton.setImage(UIImage(named: "noLoop"), forState: .Normal)
        }
    }

    
    // MARK: - Notification Handling
    func playerDidReachEndNotificationHandler(notification: NSNotification) {
        guard let playerItem = notification.object as? AVPlayerItem else { return }
        playerItem.seekToTime(kCMTimeZero)
        if !isLooping {
            isPlaying = false
            player.pause()
        } else {
            isPlaying = true
            player.play()
        }
        updatePlayPauseButton()
    }
    
    
    // MARK: - Utilities
    func removePlayerTimeObserver () {
        self.player.removeTimeObserver(TimeObserver!)
        TimeObserver = nil
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        if segue.identifier == "unwindToMovie" {
            self.player.pause()
            if let _ = TimeObserver {
                self.removePlayerTimeObserver()
            }
        }
    }


}
