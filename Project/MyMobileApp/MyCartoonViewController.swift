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
  
  var flashBool = false
  let actionSheet: [String]! = ["Envoyer", "Delete"]
  
  
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
  
  /*
  This function is called each time the app appears to screen
  */
  func didBecomeActive(notification: NSNotification) {
    CameraManager.sharedInstance.startCameraCapture()
    
    // Load the last picture
    self.fetchLastPicture()
  }
  
  @IBAction func updateFilter(sender: UISlider) {
    CameraManager.sharedInstance.updateSliderWith(self.filterSlide.value)
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
    CameraManager.sharedInstance.applyFiltertoView(self.filterView)
    CameraManager.sharedInstance.setSlider(self.filterSlide)
    self.recordButton.delegate = self
    
    // Config the miniature
    self.lastImageView.layer.borderWidth = 1
    self.lastImageView.layer.borderColor = UIColor.whiteColor().CGColor
    self.lastImageView.layer.cornerRadius = 5
    self.lastImageView.clipsToBounds = true
    self.lastImageView.userInteractionEnabled = true
    self.lastImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("goToAlbum:")))
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didBecomeActive:"), name: UIApplicationDidBecomeActiveNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("didEnterBackground:"), name: UIApplicationDidEnterBackgroundNotification, object: nil)
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
}

extension MyCartoonViewController: LongPressRecordButtonDelegate {
  
  func longPressRecordButtonDidStartLongPress(button: LongPressRecordButton) {
    CameraManager.sharedInstance.startRecording(self.flashBool)
  }
  
  func longPressRecordButtonDidStopLongPress(button: LongPressRecordButton) {
    CameraManager.sharedInstance.stopRecording()
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
    ActionSheetManager.showActionSheet(picker, title: "Action", items: self.actionSheet) {
      (choice: String?) -> Void in
      if choice == self.actionSheet[0] {
        
      } else if choice == self.actionSheet[1] {
        for asset in assets {
          AlbumManager.deleteInAlbum(asset as! PHAsset)
        }
      } else {
        
      }
    }
  }
}