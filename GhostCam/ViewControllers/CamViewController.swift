//
//  ViewController.swift
//  GhostCam
//
//  Created by Leyun Song on 15/12/18.
//  Copyright © 2015年 Leyun Song. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices


class CamViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    enum AVCamSetupResult{
        case Success
        case CameraNotAuthorized
        case SessionConfigurationFailed
    }
    
    //MARK: - Data Element
    var movie : Movie?
    var name : String?
    var filePath : String?
    var previewImage : UIImage?
    var duration : CMTime?
    var movies = [Movie]()
    var dataQueue:dispatch_queue_t?
    
    //MARK: - UI Elements Assignment
    

    @IBOutlet weak var blurOverlay: UIView!
    @IBOutlet weak var preview: UIView!
    @IBOutlet weak var MaskImageView: UIImageView!
    @IBOutlet weak var library: UIButton!
    @IBOutlet weak var settings: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var focusAndExposureTap: UITapGestureRecognizer!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var circularProgress: KDCircularProgress!
    
    
    
    //MARK: - Session Assignment
    var previewLayer:AVCaptureVideoPreviewLayer?
    var sessionQueue:dispatch_queue_t?
    var session:AVCaptureSession?
    var videoDeviceInput:AVCaptureDeviceInput?
    var movieFileOutput:AVCaptureMovieFileOutput?
    
    //MARK: - Utilities Assignment
    var setupResult:AVCamSetupResult?
    var sessionRunning:Bool?
    var backgroundRecordingID:UIBackgroundTaskIdentifier?
    
    var userSettings = Settings()
    var maxTimeInSeconds = 1
    var seconds = 0
    var timer = NSTimer()
    
    //MARK: - ViewController Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        // Disable UI
        self.recordButton.enabled = false
        //Setup the circular progress
        self.circularProgress.angle = 0
        //Setup the Session for communication
        self.session = AVCaptureSession()
        //Setup the previewLayer
        self.previewLayer = AVCaptureVideoPreviewLayer.init(session: self.session)
        //self.previewLayer!.videoGravity = AVLayerVideoGravityResize
        self.previewLayer?.frame = self.preview.superview!.bounds
        self.preview.layer.addSublayer(self.previewLayer!)
        //Setup the dispatch Queue for session and data transmission
        self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL)
        self.dataQueue = dispatch_queue_create( "data queue", DISPATCH_QUEUE_SERIAL)
        self.setupResult = AVCamSetupResult.Success
        
        //Ask for Authorization if Camara access not permitted
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
        case AVAuthorizationStatus.Authorized:break
        case AVAuthorizationStatus.NotDetermined:
            dispatch_suspend(self.sessionQueue!)
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler:{
                (granted:Bool) in
                if !granted {
                    self.setupResult = AVCamSetupResult.CameraNotAuthorized
                }
                dispatch_resume(self.sessionQueue!)
            })
        default :self.setupResult=AVCamSetupResult.SessionConfigurationFailed
        }
        
        // Setup the capture session.
        
        dispatch_async(self.sessionQueue!, {
            if self.setupResult != AVCamSetupResult.Success {
                return
            }
            self.backgroundRecordingID = UIBackgroundTaskInvalid
            
            self.session?.beginConfiguration()
        //Initialize I/O ports
            //VIDEO PORTS
            let videoDevice = CamViewController.deviceWithMediaTypeAndPosition(AVMediaTypeVideo, position: AVCaptureDevicePosition.Back)
            
            
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput.init(device: videoDevice)
                if ((self.session?.canAddInput(videoDeviceInput)) != nil){
                    self.session?.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                    self.previewLayer!.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                    
                } else {
                    print("Could not add video device input to the session")
                    self.setupResult = AVCamSetupResult.SessionConfigurationFailed
                }
            } catch let ConfigError as NSError {
                print("Could not create video device input:\(ConfigError)")
            }
            
            
            
            
            //AUDIO PORTS
            do {
                let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
                let audioDeviceInput = try AVCaptureDeviceInput.init(device: audioDevice)
                if ((self.session?.canAddInput(audioDeviceInput)) != nil){
                    self.session?.addInput(audioDeviceInput)
                } else { print("Could not add audio device input to the session")}
            } catch let ConfigError as NSError {
                print("Could not create audio device input:\(ConfigError)")
            }
            
            //MOVIE FILE PORTS
            let movieFileOutput = AVCaptureMovieFileOutput()
            if ((self.session?.canAddOutput(movieFileOutput)) != nil){
                self.session?.addOutput(movieFileOutput)
                let connection = movieFileOutput.connectionWithMediaType(AVMediaTypeVideo)
                if connection.supportsVideoStabilization {
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.Auto
                }
                self.movieFileOutput = movieFileOutput
            } else {
                print("Could not add movie file output to the session")
                self.setupResult = AVCamSetupResult.SessionConfigurationFailed
            }
            
            self.session?.commitConfiguration()
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dispatch_async(sessionQueue!, {
            self.userSettings = Settings()
            self.maxTimeInSeconds = self.userSettings.maxSeconds
            self.session?.beginConfiguration()
            //update Recording FPS
            let videoDevice = CamViewController.deviceWithMediaTypeAndPosition(AVMediaTypeVideo, position: AVCaptureDevicePosition.Back)
            switch self.userSettings.frameRate {
            case 1:
                self.setFrameRate(videoDevice, frameRate: 30)
            case 2:
                self.setFrameRate(videoDevice, frameRate: 60)
            case 3:
                self.setFrameRate(videoDevice, frameRate: 120)
            case 4:
                self.setFrameRate(videoDevice, frameRate: 240)
            default:
                self.setFrameRate(videoDevice, frameRate: 60)
            }
            self.session?.commitConfiguration()
        })
        
        
        //Load Movies
        if let savedMovies = loadMovies() {
            self.movies = savedMovies
        } else {
            showMessage("No movies found")
        }
        
        //userSettings = Settings()
        self.MaskImageView.hidden = !userSettings.mask
        
        
        // Access to CAM
        dispatch_async(self.sessionQueue!, {
            switch self.setupResult{
            case AVCamSetupResult.Success?:
                self.session?.startRunning()
                self.sessionRunning = self.session?.running
            case AVCamSetupResult.CameraNotAuthorized?:
                print("AVCam doesn't have permission to use the camera, please change privacy settings")
            case AVCamSetupResult.SessionConfigurationFailed?:
                print("Unable to capture media")
            default:
                break
            }
        })
        
        //Blur Overlay
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            self.blurOverlay.backgroundColor = UIColor.clearColor()
            
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = self.blurOverlay.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            
            self.blurOverlay.addSubview(blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
        }
        
        //Enable UI
        self.tabBarController?.tabBar.hidden = true
        self.recordButton.enabled = true
        
        
        self.recordButton.setImage(UIImage(named: "recordButton"), forState: .Normal)
        self.recordButton.setImage(UIImage(named: "recordButtonHighlighted"), forState: .Highlighted)
        self.library.setImage(UIImage(named: "libraryButton"), forState: .Normal)
        self.settings.setImage(UIImage(named: "settingsButton"), forState: .Normal)
        
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        dispatch_async(self.sessionQueue!, {
            if self.setupResult == AVCamSetupResult.Success {
                self.session!.stopRunning()
            }
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    class func deviceWithMediaTypeAndPosition (mediaType:String, position:AVCaptureDevicePosition)->AVCaptureDevice{
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType)
        var captureDevice = devices.first as! AVCaptureDevice
        
        for device in devices {
            if device.position == position {
                captureDevice = device as! AVCaptureDevice
                break
            }
        }
        return captureDevice
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    //MARK: - Actions
    @IBAction func recordStop(sender: UIButton) {
        self.recordButton.enabled = false
        
        dispatch_async(sessionQueue!, {
            //Start Recording
            if ((self.movieFileOutput?.recording) == false) {
                if let connection = self.movieFileOutput!.connectionWithMediaType(AVMediaTypeVideo) {
                    if connection.supportsVideoStabilization {
                        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.Auto
                    }
                    connection.videoOrientation = (self.previewLayer?.connection.videoOrientation)!
                }
                
                let movieFileName = self.getDateString()
                let URL = NSURL(fileURLWithPath: (Movie.DocumentsDirectory.path! + "/" + movieFileName + ".mov"))
                self.movieFileOutput?.startRecordingToOutputFileURL(URL, recordingDelegate: self)
                
                //get movie name and file path
                self.name = movieFileName
                self.filePath = URL.path!
            }
            //Stop Recording
            else {
                self.movieFileOutput?.stopRecording()
                dispatch_async(dispatch_get_main_queue(), {
                    self.timerBreak()
                    self.circularProgress.angle = 0
                })
            }
            
        })
    }
    
    

    @IBAction func focusAndExposureTap(sender: UITapGestureRecognizer) {
        let point = self.previewLayer?.captureDevicePointOfInterestForPoint(self.focusAndExposureTap.locationInView(self.focusAndExposureTap.view))
        self.focusWithMode(AVCaptureFocusMode.AutoFocus, exposureMode: AVCaptureExposureMode.AutoExpose, point: point!, monitorSubjectAreaChange: true)
    }
    
    
    
    
    //MARK: - File Output Recording Delegate
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        
        self.setupTimer()
        self.recordButton.enabled = true
        self.recordButton.setImage(UIImage(named: "recordButtonHighlighted"), forState: .Normal)
        self.library.enabled = false
        self.settings.enabled = false
        //Start Progress Animation
        self.circularProgress.animateFromAngle(0, toAngle: 360, duration: NSTimeInterval(self.seconds), completion: nil)
        //Add a subtle animation when recording start
        dispatch_async(dispatch_get_main_queue(), {
        (void) in
            self.preview.layer.opacity = 0
            UIView.animateWithDuration(0.25, animations: {
            self.preview.layer.opacity = 1
            })
        })
        
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print (outputFileURL);
        
        //circular progress clear up
        self.circularProgress.angle = 0
        
        // Create AVAsset
        let movieAsset = AVURLAsset.init(URL: outputFileURL)
        // get movie framegrasp
        let generator = AVAssetImageGenerator.init(asset: movieAsset)
        generator.appliesPreferredTrackTransform = true
        do {
            let frameTime = CMTime.init(seconds: 1.0, preferredTimescale: 1)
            let previewCGImage = try generator.copyCGImageAtTime(frameTime, actualTime: nil)
            self.previewImage = UIImage(CGImage: previewCGImage)
        }catch _ as NSError {
            print("Thumbnail capture failed")
        }
        // get duration
        self.duration = movieAsset.duration
        // Save the movie
        self.movie = Movie(name: self.name!, preview: self.previewImage!, duration: self.duration!, filePath: self.filePath!)
        self.movies.append(self.movie!)
        saveMovies()
        
        
    }
    
    // This part of code used for writing photo library
    // Inserted in didFinishingRecordingToOutputFileAtUrl to enable
    /*
    func cleanup() {
    do { try  NSFileManager.defaultManager().removeItemAtURL(outputFileURL) }
    catch let error as NSError {
    print("Error:\(error.domain)")
    }
    }
    
    PHPhotoLibrary.requestAuthorization(){
    (status:PHAuthorizationStatus) in
    
    if status == PHAuthorizationStatus.Authorized
    {
    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
    
    let options = PHAssetResourceCreationOptions()
    options.shouldMoveFile = true
    let changeRequest = PHAssetCreationRequest.creationRequestForAsset()
    changeRequest.addResourceWithType(PHAssetResourceType.Video, fileURL: outputFileURL, options: options)
    
    },
    completionHandler: {(sucess, error) in
    if sucess == true {
    print("Movie saved sucessfully!")
    } else {
    print("Error:\(error)")
    }
    })
    
    } else {
    cleanup()
    }
    }
    */
    
    //MARK: - Timer Setup
    func setupTimer(){
        self.seconds = self.maxTimeInSeconds
        self.timerLabel.hidden = false
        self.timerLabel.text = "\(seconds)"
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(CamViewController.subtractTime), userInfo: nil, repeats: true)
    }
    
    func subtractTime() {
        self.seconds -= 1
        self.timerLabel.text = "\(seconds)"
        
        if(seconds == 0)  {
            timer.invalidate()
            //self.showMessage("Time up movie captured")
            self.movieFileOutput?.stopRecording()
            self.timerLabel.hidden = true
        }
        
        
        
    }
    
    func timerBreak() {
        timer.invalidate()
        //self.showMessage("")
        self.timerLabel.hidden = true
    }
    // MARK: - Navigation
    
    @IBAction func switchToMovieLibrary(sender: UIButton) {
        self.tabBarController!.selectedIndex = 0
        self.tabBarController!.tabBar.hidden = false
    }
    @IBAction func switchToSettings(sender: UIButton) {
        self.tabBarController!.selectedIndex = 2
        self.tabBarController!.tabBar.hidden = false
    }
    
    
    
    
    // MARK: - Custom Methods
    func setFrameRate (device:AVCaptureDevice, frameRate:Int32) {
        var isFPSSupported = false
        var selectedFormat = device.activeFormat
        
        if let formats = device.formats as! [AVCaptureDeviceFormat]? {
            for format in formats {
                for range in format.videoSupportedFrameRateRanges {
                    
                    //Literate through all possible format
                    if range.maxFrameRate >= Float64(frameRate) && range.minFrameRate <= Float64(frameRate) && format.highResolutionStillImageDimensions.height < 2448{
                        
                        isFPSSupported = true
                        selectedFormat = format
                        break
                    } else {
                        print("\(format.highResolutionStillImageDimensions.height)")
                    }
                }
            }
            if( isFPSSupported ) {
                do  {
                    try device.lockForConfiguration()
                    device.activeFormat = selectedFormat
                    
                    device.activeVideoMaxFrameDuration = CMTimeMake( 1, frameRate )
                    device.activeVideoMinFrameDuration = CMTimeMake( 1, frameRate )
                    print("\(device.activeVideoMaxFrameDuration) to \(device.activeVideoMinFrameDuration)")
                    print("Selected format:\(selectedFormat)")
                    device.unlockForConfiguration()
                    
                } catch let lockError as NSError {
                    print("Could not lock device for configuration:\(lockError)")
                }
            }   else {
                print("Chosen FPS not supported on your Device")
            }
        }
        
        
    
    }
    
    
    
    
    func focusWithMode (focusMode:AVCaptureFocusMode, exposureMode:AVCaptureExposureMode, point:CGPoint, monitorSubjectAreaChange:Bool){
        dispatch_async(self.sessionQueue!, {
            let device = self.videoDeviceInput?.device
            
            do {
                try device?.lockForConfiguration()
                
                if device!.focusPointOfInterestSupported && device!.isFocusModeSupported(focusMode){
                    device!.focusMode = focusMode
                    device!.focusPointOfInterest = point
                }
                if device!.exposurePointOfInterestSupported && device!.isExposureModeSupported(exposureMode){
                    device!.exposureMode = exposureMode
                    device!.exposurePointOfInterest = point
                }
                device!.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device?.unlockForConfiguration()
            } catch let lockError as NSError {
                print("Could not lock device for configuration:\(lockError)")
            }
            
            
        })
    }
    
    
    func getDateString()->String {
        let date = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yMMD_HHmmss"
        return dateFormatter.stringFromDate(date)
    }
    
    func generatePreviewFromVideo() {
        
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
    // MARK: Data Persistence
    func saveMovies() {
        dispatch_async(dataQueue!, {
            let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(self.movies, toFile: Movie.ArchiveURL.path!)
            dispatch_async(dispatch_get_main_queue(), {
                if !isSuccessfulSave {
                    self.showMessage("Failed to save movies")
                } else {
                    self.showMessage("Movie Saved!")
                }
                
                // UI Elements Resume
                self.library.enabled = true
                self.settings.enabled = true
                self.recordButton.enabled = true
                self.recordButton.setImage(UIImage(named: "recordButton"), forState: .Normal)

                
            })
            
        })
    }
    
    func loadMovies() -> [Movie]? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(Movie.ArchiveURL.path!) as? [Movie]
    }
    
    // TODO: Orientation
    override func shouldAutorotate() -> Bool {
        //return false
        return ((self.movieFileOutput?.recording) == false)
    }
    
}



