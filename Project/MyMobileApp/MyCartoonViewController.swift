import UIKit
import GPUImage
import LongPressRecordButton
import JPSVolumeButtonHandler

class MyCartoonViewController: UIViewController {
  
  @IBOutlet var flashView: UIView!
  @IBOutlet var filterView: GPUImageView!
  @IBOutlet weak var swapCameraButton: UIButton!
  @IBOutlet weak var lastMiniatureButton: UIButton!
  @IBOutlet weak var recordButton: LongPressRecordButton!
  
  var volumeButtonHandler: JPSVolumeButtonHandler?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    self.setup()

    self.recordButton.delegate = self
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    self.setup()
    
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.view.backgroundColor = UIColor.clearColor()
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    CameraManager.sharedInstance.stopCameraCapture()
  }
  
  @IBAction func goToLastTakenPicture() {
    
  }
  
  @IBAction func swapCamera() {
    CameraManager.sharedInstance.rotateCamera()
  }
  
  func setup() {
    CameraManager.sharedInstance.applyFiltertoView(filterView)
    CameraManager.sharedInstance.startCameraCapture()

    self.volumeButtonHandler = JPSVolumeButtonHandler(upBlock: { () -> Void in
      CameraManager.sharedInstance.filterUp()
    }, downBlock: { () -> Void in
      CameraManager.sharedInstance.filterDown()
    })
    
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
    CameraManager.sharedInstance.shoot()
    return false
  }
}

