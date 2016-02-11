import UIKit
import GPUImage

class FilterDisplayViewController: UIViewController, UISplitViewControllerDelegate {
  
  @IBOutlet var flashView: UIView!
  @IBOutlet var filterView: GPUImageView?
  @IBOutlet weak var filterSlider: UISlider!
  @IBOutlet weak var takePictureButton: UIButton!
  @IBOutlet weak var takeVideoButton: UIButton!
  @IBOutlet weak var swapCameraButton: UIButton!
  @IBOutlet weak var lastMiniatureButton: UIButton!
  
  let videoCamera: GPUImageVideoCamera
  let filterOperation: FilterOperationInterface = filterOperations[0]
  
  var pathToMovie: NSString!
  var movieWritertemp: GPUImageMovieWriter!
  
  required init(coder aDecoder: NSCoder) {
    self.videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSessionPresetHigh, cameraPosition: .Back)
    self.videoCamera.outputImageOrientation = .Portrait
    self.videoCamera.horizontallyMirrorFrontFacingCamera = false
    self.videoCamera.horizontallyMirrorRearFacingCamera = false
    
    super.init(coder: aDecoder)!
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.configureView()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.view.backgroundColor = UIColor.clearColor()
    self.configureView()
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    
    videoCamera.stopCameraCapture()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  @IBAction func updateSliderValue() {
    switch (self.filterOperation.sliderConfiguration) {
    case .Enabled(_, _, _):
      self.filterOperation.updateBasedOnSliderValue(CGFloat(self.filterSlider!.value)) // If the UISlider isn't wired up, I want this to throw a runtime exception
    case .Disabled:
      break
    }
  }
  
  @IBAction func takePicture() {
    videoCamera.pauseCameraCapture()
    filterOperation.filter.useNextFrameForImageCapture()
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      let capturedImage: UIImage =  self.filterOperation.filter.imageFromCurrentFramebuffer()
      
      UIImageWriteToSavedPhotosAlbum(capturedImage, nil, nil, nil)
      AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    })
    videoCamera.resumeCameraCapture()
  }
  
  func stopVideo() { UISaveVideoAtPathToSavedPhotosAlbum(pathToMovie as String, nil, nil, nil)
  }
  
  @IBAction func takeVideo() {
    
    self.pathToMovie = NSHomeDirectory().stringByAppendingString("/Documents/mymobileapp.m4v")
    unlink(self.pathToMovie.UTF8String)
    let movieURL: NSURL = NSURL.fileURLWithPath(self.pathToMovie as String)
    
    self.movieWritertemp = GPUImageMovieWriter.init(movieURL: movieURL, size: CGSizeMake(480, 320))
    self.movieWritertemp.encodingLiveVideo = true
    self.filterOperation.filter.addTarget(self.movieWritertemp)
    
    
    let  startTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
    dispatch_after(startTime, dispatch_get_main_queue(), { () -> Void in
      self.videoCamera.audioEncodingTarget = self.movieWritertemp
      
      self.movieWritertemp.startRecording()
  
      let  stopTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(NSEC_PER_SEC)))
      dispatch_after(stopTime, dispatch_get_main_queue(), { () -> Void in
        self.filterOperation.filter.removeTarget(self.movieWritertemp)
        self.videoCamera.audioEncodingTarget = nil
        self.movieWritertemp.finishRecording()
                UISaveVideoAtPathToSavedPhotosAlbum(self.pathToMovie as String, nil, nil, nil)
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
      })
    })
    
  }
  
  @IBAction func goToLastTakenPicture() {
    
  }
  
  @IBAction func swapCamera() {
    videoCamera.rotateCamera()
  }
  
  func configureView() {
    self.title = self.filterOperation.titleName
    switch self.filterOperation.filterOperationType {
    case .SingleInput:
      videoCamera.addTarget((self.filterOperation.filter as! GPUImageInput))
      self.filterOperation.filter.addTarget(self.filterView)
    default:
      break
    }
    
    videoCamera.startCameraCapture()
    
    switch self.filterOperation.sliderConfiguration {
    case .Disabled:
      self.filterSlider.hidden = true
    case let .Enabled(minimumValue, maximumValue, initialValue):
      self.filterSlider.minimumValue = minimumValue
      self.filterSlider.maximumValue = maximumValue
      self.filterSlider.value = initialValue
      self.filterSlider.hidden = false
      self.updateSliderValue()
    }
  }
}

