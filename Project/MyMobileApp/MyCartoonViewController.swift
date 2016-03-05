import UIKit
import GPUImage
import LongPressRecordButton
import Photos
import WPMediaPicker

class MyCartoonViewController: UIViewController {
  
  @IBOutlet weak var filterView: GPUImageView!
  @IBOutlet weak var swapCameraButton: UIButton!
  @IBOutlet weak var recordButton: LongPressRecordButton!
  @IBOutlet weak var lastImageView: UIImageView!
  @IBOutlet weak var flashButton: UIButton!
  @IBOutlet weak var filterSlide: UISlider!
  @IBOutlet weak var timerVideo: UILabel!
  @IBOutlet weak var noCameraLabel: UILabel!
  
  var timer = NSTimer()
  var time = 10
  var flashBool = false
  let actionSheet: [String]! = ["Delete"]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setup()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    CameraManager.sharedInstance.startCameraCapture()
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    CameraManager.sharedInstance.stopCameraCapture()
  }
    
  func updateRotate() {
    // Map UIDeviceOrientation to UIInterfaceOrientation.
    var orient = UIInterfaceOrientation.Portrait
    
    switch UIDevice.currentDevice().orientation {
    case UIDeviceOrientation.LandscapeLeft:
      orient = UIInterfaceOrientation.LandscapeLeft
    case UIDeviceOrientation.LandscapeRight:
      orient = UIInterfaceOrientation.LandscapeRight
    case UIDeviceOrientation.Portrait:
      orient = UIInterfaceOrientation.Portrait
    case UIDeviceOrientation.PortraitUpsideDown:
      orient = UIInterfaceOrientation.PortraitUpsideDown
    default:
      orient = UIInterfaceOrientation.Portrait
    }
    CameraManager.sharedInstance.camera.outputImageOrientation = orient
  }
  
  /*
  Enable/Disable Flash/Torch
  */
  @IBAction func flashChanged(sender: UIButton) {
    flashBool = !flashBool
    
    if flashBool == true {
      flashButton.setImage(UIImage(named: "flash"), forState: UIControlState.Normal)
    } else {
      flashButton.setImage(UIImage(named: "noflash"), forState: UIControlState.Normal)
    }
  }
  
  /*
  Change the camera to front/back
  */
  @IBAction func swapCamera() {
    CameraManager.sharedInstance.rotateCamera()
  }
  
  @IBAction func updateFilter(sender: UISlider) {
    CameraManager.sharedInstance.updateSliderWith(self.filterSlide.value)
  }
  
  /*
  This function is called each time the app appears to screen
  */
  func didBecomeActive(notification: NSNotification) {
    CameraManager.sharedInstance.startCameraCapture()
    
    // Load the last picture
    self.fetchLastPicture()
  }
  
  /*
  This function is called each time the app disappears to screen
  */
  func didEnterBackground(notification: NSNotification) {
    // Load the last picture
    CameraManager.sharedInstance.stopCameraCapture()
  }
  
  /*
  Setup the app
  */
  func setup() {
    
    // Config the miniature
    self.lastImageView.layer.borderWidth = 1
    self.lastImageView.layer.borderColor = UIColor.whiteColor().CGColor
    self.lastImageView.layer.cornerRadius = 5
    self.lastImageView.clipsToBounds = true
    self.lastImageView.userInteractionEnabled = true
    self.lastImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("goToAlbum:")))
    
    if CameraManager.sharedInstance.camera == nil {
      self.noCameraLabel.hidden = false
      self.fetchLastPicture()
    } else {
      self.noCameraLabel.hidden = true
      CameraManager.sharedInstance.applyFiltertoView(self.filterView)
      CameraManager.sharedInstance.setSlider(self.filterSlide)
      self.recordButton.delegate = self
      
      NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didBecomeActive:"), name: UIApplicationDidBecomeActiveNotification, object: nil)
      NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didEnterBackground:"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
  }
  
  /*
  Launch a Photo Gallery
  */
  func goToAlbum(gesture: UITapGestureRecognizer) {
    let mediaPicker: WPMediaPickerViewController = WPMediaPickerViewController()
    
    mediaPicker.delegate = self
    mediaPicker.allowCaptureOfMedia = false
    self.presentViewController(mediaPicker, animated: true, completion:nil)
  }
  
  /*
  Fetch the last picture to display on the miniature
  */
  func fetchLastPicture() {
    let imgManager = PHImageManager.defaultManager()
    
    // Sort the images by creation date
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: true)]
    
    if let fetchResult: PHFetchResult = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: fetchOptions) {
      
      if fetchResult.count > 0 {
        imgManager.requestImageForAsset(fetchResult.lastObject as! PHAsset, targetSize: self.lastImageView.frame.size, contentMode: .AspectFill, options: nil) { (image: UIImage?, info: [NSObject : AnyObject]?) -> Void in
          self.lastImageView.image = image
        }
      }
    }
  }
  
  func timerAction() {
    self.time--
    self.timerVideo.text = "\(self.time)"
    
    if self.time == 0 {
      longPressRecordButtonDidStopLongPress(recordButton)
//      self.timerVideo.hidden = true
//      CameraManager.sharedInstance.stopRecording()
//      self.timer.invalidate()
    }
  }
  
}

extension MyCartoonViewController: LongPressRecordButtonDelegate {
  
  func longPressRecordButtonDidStartLongPress(button: LongPressRecordButton) {
    self.timerVideo.hidden = false
    self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "timerAction", userInfo: nil, repeats: true)
    
    CameraManager.sharedInstance.startRecording(self.flashBool)
  }
  
  func longPressRecordButtonDidStopLongPress(button: LongPressRecordButton) {
    if self.timer.valid == true {
      CameraManager.sharedInstance.stopRecording()
    }
    
    self.timerVideo.hidden = true
    self.time = 10
    self.timerVideo.text = "10"
    self.timer.invalidate()
  }
  
  func longPressRecordButtonShouldShowToolTip(button: LongPressRecordButton) -> Bool {
    CameraManager.sharedInstance.shoot(self.lastImageView, hasFlash: self.flashBool)
    return false
  }
}

extension MyCartoonViewController: WPMediaPickerViewControllerDelegate {
  
  func mediaPickerControllerDidCancel(picker: WPMediaPickerViewController) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func mediaPickerController(picker: WPMediaPickerViewController, didFinishPickingAssets assets: [AnyObject]) {
    if assets.count > 0 {
      ActionSheetManager.showActionSheet(picker, title: "Action", items: self.actionSheet) {
        (choice: String?) -> Void in
        if choice == self.actionSheet[0] {
          for asset in assets {
            AlbumManager.deleteInAlbum(asset as! PHAsset)
          }
        }
      }
    }
  }
}