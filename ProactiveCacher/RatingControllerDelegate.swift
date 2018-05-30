//
//  RatingControllerDelegate.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 30/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit
import Cosmos

protocol RatingControllerDelegate {
    /**
     Create a `CosmosView` for handling the user input for rating the video after the user finished watching it.
     - parameter presentingView: view over which the `UIAlertController` containing the `CosmosView` will be presented. Its `frame` is used for sizing the `CosmosView`.
     */
    func createRatingView(fitting presentingView:UIView) -> CosmosView
    
    /**
     Create a `UIAlertController` with an embedded `CosmosView` for rating the watched video file. Add actions for uploading the rating to the server or cancelling the rating.
     - parameter ratingView: `CosmosView` to embed in the alert controller
     - parameter video: `Video` that is being rated
     - parameter presentingView: view used for sizing the `ratingView`
     */
    func alertControllerForRating(embedding ratingView:CosmosView,of video:Video, presentingView:UIView) -> UIAlertController
    
    /**
     Apply a size transformation to a `UIView` on an iPad or return the original view on an iPhone. Use this method to size a `UIView` that will be used as the `popoverPresentationController` of a `UIAlertController`.
     */
    func transformPresentingView(_ originalPresentingView:UIView) -> UIView
}

extension RatingControllerDelegate {
    func transformPresentingView(_ originalPresentingView:UIView)->UIView {
        let presentingView: UIView
        if UIDevice.current.userInterfaceIdiom == .pad {
            presentingView = UIView(frame: originalPresentingView.frame.applying(CGAffineTransform(scaleX: 1/3, y: 1/3)))
        } else {
            presentingView = originalPresentingView
        }
        return presentingView
    }
    
    func createRatingView(fitting presentingView:UIView) -> CosmosView {
        let starCount = 5
        let ratingView = CosmosView()
        ratingView.settings.minTouchRating = 0
        ratingView.settings.totalStars = starCount
        ratingView.settings.updateOnTouch = true
        ratingView.settings.fillMode = .half
        ratingView.settings.starMargin = 5
        // Stars were still slightly too big, since the UIAlertController's width is smaller than the screen width, so added a constant 20 value, which seems to be the padding value on all devices, but if the app will support iPad, this will need to change, since an alert isn't full screen there
        // However, the starSize need to be known before creating the UIAlertController, since intrinsically the UIAlertController sizes itself to fit the customView when it's initialized
        ratingView.settings.starSize = (Double(presentingView.frame.width-20)-Double(starCount+1)*ratingView.settings.starMargin)/Double(starCount)
        ratingView.settings.emptyImage = UIImage(named: "GoldStarEmpty")
        ratingView.settings.filledImage = UIImage(named: "GoldStar")
        ratingView.translatesAutoresizingMaskIntoConstraints = false
        ratingView.addConstraint(NSLayoutConstraint(item: ratingView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: CGFloat(ratingView.settings.starSize)))
        return ratingView
    }
    
    func alertControllerForRating(embedding ratingView:CosmosView,of video:Video, presentingView:UIView) -> UIAlertController {
        let ratingController = UIAlertController(title: "Please rate the video you just watched", customView: ratingView, fallbackMessage: "This should be a cosmos view", preferredStyle: .actionSheet)
        ratingController.addAction(UIAlertAction(title: "Done", style: .default, handler: { action in
            if let rating = video.rating.value {
                CacheServerAPI.shared.rateVideo(with: video.youtubeID, rating: rating, completion: { result in
                    switch result {
                    case .success(_):
                        print("Rating successfully uploaded")
                    case let .failure(error):
                        print("Error uploading rating: \(error)")
                    }
                })
            } else {
                print("Done pushed without choosing a rating")
            }
        }))
        ratingController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        // TODO: Needed for iPad - tweak this, the ratingController is completely flawed
        ratingController.popoverPresentationController?.sourceView = presentingView
        ratingController.popoverPresentationController?.permittedArrowDirections = []
        ratingController.popoverPresentationController?.sourceRect = CGRect(x: presentingView.bounds.midX, y: presentingView.bounds.midY, width: 0, height: 0)
        return ratingController
    }
}
