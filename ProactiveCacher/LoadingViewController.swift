//
//  LoadingViewController.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 19/04/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIViewController.addActivityIndicator(activityIndicator: activityIndicator, view: self.view)
        activityIndicator.startAnimating()
        // Videos can safely be loaded since the user is registered, so perform the segue
        if CacheServerAPI.shared.userID != nil {
            displayVideos()
        }
    }
    
    func displayVideos(){
        activityIndicator.stopAnimating()
        performSegue(withIdentifier: "VideoListViewSegue", sender: nil)
    }
}

extension UIViewController {
    /**
     Add an activity indicator to the specified view. Set Autolayout constraints to keep the indicator in the middle of the screen.
     - parameter activityIndicator: activityIndicator view to be added
     - parameter view: UIView to which the activity indicator should be added as a subview
     */
    static func addActivityIndicator(activityIndicator: UIActivityIndicatorView,view:UIView){
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.black
        let horizontalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(horizontalConstraint)
        let verticalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalConstraint)
    }
}
