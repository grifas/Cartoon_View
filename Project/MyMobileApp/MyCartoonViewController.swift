import UIKit
import GPUImage
import LongPressRecordButton
import JPSVolumeButtonHandler
import Photos
import BSImagePicker

class MyCartoonViewController: UIViewController {
  
  @IBOutlet weak var flashView: UIView!
  @IBOutlet weak var filterView: GPUImageView!
  @IBOutlet weak var swapCameraButton: UIButton!
  @IBOutlet weak var recordButton: LongPressRecordButton!
  @IBOutlet weak var lastImageView: UIImageView!
  
  var volumeButtonHandler: JPSVolumeButtonHandler?
  
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
    self.recordButton.delegate = self

    // Override Volume Control
    self.volumeButtonHandler = JPSVolumeButtonHandler(upBlock: { () -> Void in
      CameraManager.sharedInstance.filterUp()
      }, downBlock: { () -> Void in
        CameraManager.sharedInstance.filterDown()
    })
    
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
    let vc = BSImagePickerViewController()
    
    bs_presentImagePickerController(vc, animated: true,
      select: { (asset: PHAsset) -> Void in
        // User selected an asset.
        // Do something with it, start upload perhaps?
      }, deselect: { (asset: PHAsset) -> Void in
        // User deselected an assets.
        // Do something, cancel upload?
      }, cancel: { (assets: [PHAsset]) -> Void in
        // User cancelled. And this where the assets currently selected.
      }, finish: { (assets: [PHAsset]) -> Void in
        // User finished with these assets
      }, completion: nil)
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
    CameraManager.sharedInstance.startRecording()
  }
  
  func longPressRecordButtonDidStopLongPress(button: LongPressRecordButton) {
    CameraManager.sharedInstance.stopRecording()
  }
  
  func longPressRecordButtonShouldShowToolTip(button: LongPressRecordButton) -> Bool {
    CameraManager.sharedInstance.shoot(self.lastImageView)
    return false
  }
}

