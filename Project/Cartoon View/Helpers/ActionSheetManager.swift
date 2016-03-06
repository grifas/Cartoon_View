//
//  ActionSheetManager.swift
//  Cartoon View
//
//  Created by Aurelien Grifasi on 21/02/16.
//  Copyright © 2016 aurelien.grifasi. All rights reserved.
//

import UIKit

class ActionSheetManager {
  
  static func showActionSheet(viewController: UIViewController, title: String, items: [String], action: ((choice: String?) -> Void)!) {
    
    let optionMenu = UIAlertController(title: title, message: nil, preferredStyle: .ActionSheet)
    
    for item in items {
      let newAction = UIAlertAction(title: item, style: .Default, handler: {
        (alert: UIAlertAction) -> Void in
        action(choice: alert.title)
      })
      optionMenu.addAction(newAction)
      
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: {
      (alert: UIAlertAction) -> Void in
      action(choice: nil)
    })
    optionMenu.addAction(cancelAction)
    
    // Handle popover on iPhone and iPad
//    let popOver = optionMenu.popoverPresentationController
//    popOver?.sourceView = viewController.navigationItem.rightBarButtonItem?.customView
//    popOver?.sourceRect = viewController.navigationItem.rightBarButtonItem!.customView!.bounds
//    popOver?.permittedArrowDirections = UIPopoverArrowDirection.Any
    
    viewController.presentViewController(optionMenu, animated: true, completion: nil)
  }
}