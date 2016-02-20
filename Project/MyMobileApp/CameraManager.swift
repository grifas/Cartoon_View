//
//  CameraManager.swift
//  MyMobileApp
//
//  Created by Aurelien Grifasi on 17/02/16.
//  Copyright © 2016 aurelien.grifasi. All rights reserved.
//

import UIKit
import GPUImage

class CameraManager {
  
  class var sharedInstance: CameraManager {
    struct Static {
      static var instance: CameraManager?
      static var token: dispatch_once_t = 0
    }
    
    dispatch_once(&Static.token) {
      Static.instance = CameraManager()
    }
    return Static.instance!
  }
  
  let camera: GPUImageStillCamera
  
  //To Filter
  let filterOperation: FilterOperationInterface = filterOperations[0]
  var slider = UISlider()
  
  // To Video
  var pathToMovie: NSString?
  var movieWritertemp: GPUImageMovieWriter!
  
  init() {
    // Init Camera
    self.camera = GPUImageStillCamera(sessionPreset: AVCaptureSessionPresetHigh, cameraPosition: .Back)
    self.camera.outputImageOrientation = .Portrait
    self.camera.horizontallyMirrorFrontFacingCamera = true
    self.camera.horizontallyMirrorRearFacingCamera = false
  }
  
  func applyFiltertoView(filterView: GPUImageView) {
    switch self.filterOperation.filterOperationType {
    case .SingleInput:
      self.camera.addTarget((self.filterOperation.filter as! GPUImageInput))
      self.filterOperation.filter.addTarget(filterView)
      self.setSlider()
    default:
      break
    }
  }
  
  func setSlider() {
    switch self.filterOperation.sliderConfiguration {
    case let .Enabled(minimumValue, maximumValue, initialValue):
      self.slider.minimumValue = minimumValue
      self.slider.maximumValue = maximumValue
      self.slider.value = initialValue
    default:
      break
    }
  }
  
  /*
  Start Camera Capture
  */
  func startCameraCapture() {
    self.camera.startCameraCapture()
  }
  
  /*
  Stop Camera Capture
  */
  func stopCameraCapture() {
    self.camera.stopCameraCapture()
  }
  
  /*
  Rotate Camera
  */
  func rotateCamera() {
    self.camera.rotateCamera()
  }
  
  /*
  Update filter rate to down
  */
  func filterDown() {
    let value = self.slider.value - 1
    
    if value >= self.slider.minimumValue {
      self.updateSliderWith(value)
      self.slider.value = value
    }
  }
  
  /*
  Update filter rate to up
  */
  func filterUp() {
    let value = self.slider.value + 1
    
    if value <= self.slider.maximumValue {
      self.updateSliderWith(value)
      self.slider.value = value
    }
  }
  
  /*
  Update Slider Value
  */
  func updateSliderWith(value: Float) {
    switch (self.filterOperation.sliderConfiguration) {
    case .Enabled(_, _, _):
      self.filterOperation.updateBasedOnSliderValue(CGFloat(value))
    case .Disabled:
      break
    }
  }

  /*
  Enable Flash
  */
  func enableFlash() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      do {
        try self.camera.inputCamera.lockForConfiguration()
        self.camera.inputCamera.flashMode = AVCaptureFlashMode.On
        self.camera.inputCamera.unlockForConfiguration()
      } catch {
        print("The Flash can not be enabled")
      }
    })
  }

  /*
  Disable Flash
  */
  func disableFlash() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      do {
        try self.camera.inputCamera.lockForConfiguration()
        self.camera.inputCamera.flashMode = AVCaptureFlashMode.Off
        self.camera.inputCamera.unlockForConfiguration()
      } catch {
        print("The Flash can not be disabled")
      }
    })
  }
  
  /*
  Enable Torch
  */
  func enableTorch() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      do {
        try self.camera.inputCamera.lockForConfiguration()
        if self.camera.inputCamera.torchAvailable {
          self.camera.inputCamera.torchMode = AVCaptureTorchMode.On
        }
        self.camera.inputCamera.unlockForConfiguration()
      } catch {
        print("The Torch can not be enabled")
      }
    })
  }
  
  /*
  Disable Torch
  */
  func disableTorch() {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      do {
        try self.camera.inputCamera.lockForConfiguration()
        self.camera.inputCamera.torchMode = AVCaptureTorchMode.Off
        self.camera.inputCamera.unlockForConfiguration()
      } catch {
        print("The Torch can not be disabled")
      }
    })
  }

  
  // ---------------- About Picture
  
  /*
  Take a Picture
  */
  func shoot(imageView: UIImageView, hasFlash: Bool = false) {
    if hasFlash == true {
      self.enableFlash()
    } else {
      self.disableFlash()
    }
    self.camera.pauseCameraCapture()
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.camera.capturePhotoAsImageProcessedUpToFilter(self.filterOperation.filter, withCompletionHandler: { (image, error) -> Void in
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        imageView.image = image
      })
    })
    self.camera.resumeCameraCapture()
  }
  
  // ---------------- About Video
  
  /*
  Start Video Recording
  */
  func startRecording(hasTorch: Bool = false) {
    self.pathToMovie = NSHomeDirectory().stringByAppendingString("/Documents/mymobileapp.m4v")
    
    if let path = self.pathToMovie {
      unlink(path.UTF8String)
      let movieURL: NSURL = NSURL.fileURLWithPath(path as String)
      
      self.movieWritertemp = GPUImageMovieWriter.init(movieURL: movieURL, size: CGSizeMake(480, 320))
      self.movieWritertemp.encodingLiveVideo = true
      self.filterOperation.filter.addTarget(self.movieWritertemp)
      
      let  startTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
      dispatch_after(startTime, dispatch_get_main_queue(), { () -> Void in
        self.camera.audioEncodingTarget = self.movieWritertemp
        self.movieWritertemp.startRecording()
        if hasTorch == true {
          self.enableTorch()
        } else {
          self.disableTorch()
        }
      })
    }
  }
  
  /*
  Stop Video Recording
  */
  func stopRecording() {
    if let path = self.pathToMovie {
      let stopTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
      dispatch_after(stopTime, dispatch_get_main_queue(), { () -> Void in
        self.filterOperation.filter.removeTarget(self.movieWritertemp)
        self.camera.audioEncodingTarget = nil
        self.movieWritertemp.finishRecording()
        UISaveVideoAtPathToSavedPhotosAlbum(path as String, nil, nil, nil)
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
      })
    }
  }
}