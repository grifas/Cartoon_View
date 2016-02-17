import UIKit
import GPUImage
import LongPressRecordButton

class MyCartoonViewController: UIViewController {
  
  @IBOutlet var flashView: UIView!
  @IBOutlet var filterView: GPUImageView!
  @IBOutlet weak var filterSlider: UISlider!
  @IBOutlet weak var swapCameraButton: UIButton!
  @IBOutlet weak var lastMiniatureButton: UIButton!
  @IBOutlet weak var recordButton: LongPressRecordButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    CameraManager.sharedInstance.applyFiltertoView(filterView)
    CameraManager.sharedInstance.setSlider(filterSlider)
    CameraManager.sharedInstance.startCameraCapture()

    self.recordButton.delegate = self
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    CameraManager.sharedInstance.applyFiltertoView(filterView)
    CameraManager.sharedInstance.setSlider(filterSlider)
    CameraManager.sharedInstance.startCameraCapture()
    
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.view.backgroundColor = UIColor.clearColor()
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    CameraManager.sharedInstance.stopCameraCapture()
  }
  
  @IBAction func updateSliderValue() {
    CameraManager.sharedInstance.updateSliderWith(self.filterSlider.value)
  }
  
  @IBAction func goToLastTakenPicture() {
    
  }
  
  @IBAction func swapCamera() {
    CameraManager.sharedInstance.rotateCamera()
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

