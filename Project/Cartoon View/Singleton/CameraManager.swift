//
//  CameraManager.swift
//  Cartoon View
//
//  Created by Aurelien Grifasi on 17/02/16.
//  Copyright © 2016 aurelien.grifasi. All rights reserved.
//

import UIKit
import GPUImage

class CameraManager {
  
  // Singleton
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
  
  let camera: GPUImageStillCamera!
    
  //To Filter
  let filterOperation: FilterOperationInterface = filterOperations[0]
  
  // To Record
  var movieURL: NSURL!
  var movieWriter: GPUImageMovieWriter!

  /*
  Init Camera and Create folder if needed
  */
  init() {
    if let camera = GPUImageStillCamera(sessionPreset: AVCaptureSessionPresetHigh, cameraPosition: .Back) {
      self.camera = camera
      self.camera.outputImageOrientation = .Portrait
      self.camera.horizontallyMirrorFrontFacingCamera = true
      self.camera.horizontallyMirrorRearFacingCamera = false
      
      AlbumManager.createFolder()
    } else {
      self.camera = nil
    }
  }
  
  /*
  Apply filter on provided view
  */
  func applyFiltertoView(filterView: GPUImageView) {
    switch self.filterOperation.filterOperationType {
    case .SingleInput:
      self.camera.addTarget((self.filterOperation.filter as! GPUImageInput))
      self.filterOperation.filter.addTarget(filterView)
    default:
      break
    }
  }
  
  /*
  Set slider
  */
  func setSlider(slider: UISlider) {
    switch self.filterOperation.sliderConfiguration {
    case let .Enabled(minimumValue, maximumValue, initialValue):
      slider.minimumValue = minimumValue
      slider.maximumValue = maximumValue
      slider.value = initialValue
    default:
      break
    }
  }
  
  /*
  Start Camera Capture
  */
  func startCameraCapture() {
    if self.camera != nil {
      self.camera.startCameraCapture()
    }
  }
  
  /*
  Stop Camera Capture
  */
  func stopCameraCapture() {
    if self.camera != nil {
    self.camera.stopCameraCapture()
    }
  }
  
  /*
  Rotate Camera
  */
  func rotateCamera() {
    if self.camera != nil {
    self.camera.rotateCamera()
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
        if self.camera.inputCamera.torchAvailable == true {
          self.camera.inputCamera.torchMode = AVCaptureTorchMode.Off
        }
        self.camera.inputCamera.unlockForConfiguration()
      } catch {
        print("The Torch can not be disabled")
      }
    })
  }
  
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
        if let image = image {
          imageView.image = image
          AlbumManager.saveImage(image)
        }
      })
    })
    self.camera.resumeCameraCapture()
  }

  /*
  Start Video Recording
  */
  func startRecording(hasTorch: Bool = false) {
    
    let pathToMovie: NSString = NSHomeDirectory().stringByAppendingString("/Documents/cartoonview.m4v")

    unlink(pathToMovie.UTF8String)
    self.movieURL = NSURL.fileURLWithPath(pathToMovie as String)
      
    self.movieWriter = GPUImageMovieWriter.init(movieURL: movieURL, size: CGSizeMake(480, 640))
    self.movieWriter.encodingLiveVideo = true
    self.filterOperation.filter.addTarget(self.movieWriter)
    self.camera.audioEncodingTarget = self.movieWriter
    
    let startTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
    dispatch_after(startTime, dispatch_get_main_queue(), { () -> Void in
      self.movieWriter.startRecording()
      if hasTorch == true {
        self.enableTorch()
      } else {
        self.disableTorch()
      }
    })
  }
  
  /*
  Stop Video Recording
  */
  func stopRecording() {
    let stopTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
    dispatch_after(stopTime, dispatch_get_main_queue(), { () -> Void in
      self.filterOperation.filter.removeTarget(self.movieWriter)
      self.camera.audioEncodingTarget = nil
      self.movieWriter.finishRecording()
      AlbumManager.saveVideo(self.movieURL)
    })
  }
}
