//
//  AlbumManager.swift
//  MyMobileApp
//
//  Created by Aurelien Grifasi on 21/02/16.
//  Copyright © 2016 aurelien.grifasi. All rights reserved.
//

import Photos

class AlbumManager {
 
  // To Create Folder
  static var assetCollection: PHAssetCollection!
  static var albumFound : Bool = false
  static var photosAsset: PHFetchResult!
  static var assetCollectionPlaceholder: PHObjectPlaceholder!

  /*
  Create the Cartoon Folder
  */
  static func createFolder() {
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "title = %@", "Cartoon")
    let collection : PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
    
    if let firstObj: AnyObject = collection.firstObject {
      self.albumFound = true
      self.assetCollection = firstObj as! PHAssetCollection
    } else {
      PHPhotoLibrary.sharedPhotoLibrary().performChanges({
        let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle("Cartoon")
        self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
          self.albumFound = success ? true: false
          
          if success {
            let collectionFetchResult = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([self.assetCollectionPlaceholder.localIdentifier], options: nil)
            self.assetCollection = collectionFetchResult.firstObject as! PHAssetCollection
          }
      })
    }
  }
  
  /*
  Save Picture in Cartoon Folder
  */
  static func saveImage(image: UIImage) {
    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
      let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(image)
      let assetPlaceholder = assetRequest.placeholderForCreatedAsset
      self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: nil)
      
      if let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection, assets: self.photosAsset) {
        albumChangeRequest.addAssets([assetPlaceholder!])
      }
      }, completionHandler: { success, error in
    })
  }
  
  /*
  Save Video in Cartoon Folder
  */
  static func saveVideo(url: NSURL) {
    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
      let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)
      let assetPlaceholder = assetRequest!.placeholderForCreatedAsset
      self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: nil)
      
      if let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection, assets: self.photosAsset) {
        albumChangeRequest.addAssets([assetPlaceholder!])
      }
      }, completionHandler: { success, error in
        if success {
          AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    })
  }

  /*
  Delete Photo and Video in Cartoon Folder
  */
  static func deleteInAlbum(asset: PHAsset) {
    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
      self.photosAsset = PHAsset.fetchAssetsInAssetCollection(self.assetCollection, options: nil)
      
      if let request = PHAssetCollectionChangeRequest(forAssetCollection: self.assetCollection, assets: self.photosAsset) {
        request.removeAssets([asset])
      }
      }, completionHandler: {success, error in
        if success {
          AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
    })
    
  }



}