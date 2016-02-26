import UIKit
import GPUImage
import LongPressRecordButton
import JPSVolumeButtonHandler
import Photos
import OHQBImagePicker

class MyCartoonViewController: UIViewController {
  
  @IBOutlet weak var flashView: UIView!
  @IBOutlet weak var filterView: GPUImageView!
  @IBOutlet weak var swapCameraButton: UIButton!
  @IBOutlet weak var recordButton: LongPressRecordButton!
  @IBOutlet weak var lastImageView: UIImageView!
  @IBOutlet weak var flashButton: UIButton!

  var flashBool = false
  var volumeButtonHandler: JPSVolumeButtonHandler?
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
    let imagePickerController: QBImagePickerController = QBImagePickerController()
    
    imagePickerController.navigationController?.navigationItem.rightBarButtonItem = nil
    imagePickerController.navigationController?.navigationItem.rightBarButtonItem
    imagePickerController.delegate = self
    imagePickerController.allowsMultipleSelection = true
    imagePickerController.maximumNumberOfSelection = 1
    imagePickerController.showsNumberOfSelectedItems = true
    
    self.presentViewController(imagePickerController, animated: true, completion: nil)
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

extension MyCartoonViewController: QBImagePickerControllerDelegate {
    
  func qb_imagePickerController(imagePickerController: QBImagePickerController!, didSelectItem item: NSObject!) {
    ActionSheetManager.showActionSheet(imagePickerController, title: "Action", items: self.actionSheet) {
      (choice: String?) -> Void in
      if choice == self.actionSheet[0] {
        
      } else if choice == self.actionSheet[1] {
        AlbumManager.deleteInAlbum(item as! PHAsset)
      } else {
        
      }
    }
  }

  func qb_imagePickerControllerDidCancel(imagePickerController: QBImagePickerController!) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }

}

