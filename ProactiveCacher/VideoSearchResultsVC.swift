//
//  VideoSearchResultsVC.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 24/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

// If I decide to use another VC that's pushed from the VideoListVC need to make sure that there's no code duplication between the two
// Should probably create a superclass that is generic on its data source and make both classes inherit form that
class VideoSearchResultsVC: UIViewController, RatingControllerDelegate {
    
    @IBOutlet weak var searchResultsTable: UITableView!
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var videoResults = [YouTubeVideo]()
    var watchedVideoIndex: Int? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        UIViewController.addActivityIndicator(activityIndicator: activityIndicator, view: self.view)
        searchResultsTable.rowHeight = searchResultsTable.frame.width/16*9
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Present the rating view if the user was watching a video
        if let justWatchedVideoIndex = watchedVideoIndex {
            self.watchedVideoIndex = nil
            let presentingView = transformPresentingView(self.view)
            let ratingView = createRatingView(fitting: presentingView)
            let videoToShare = Video()
            videoToShare.youtubeID = videoResults[justWatchedVideoIndex].id
            videoToShare.title = videoResults[justWatchedVideoIndex].title
            // Save thumbnail and assign the saved path to thumbnailPath
            //videoToShare.thumbnailPath =
            ratingView.didFinishTouchingCosmos = { rating in
                videoToShare.rating.value = rating
            }
            // Create the alert and show it
            let ratingController = alertControllerForRating(embedding: ratingView, presentingView: presentingView)
            // Add an action for sharing, but not rating the video
            ratingController.addAction(shareVideoAlertAction(video: videoToShare))
            ratingController.addAction(shareAndRateVideoAlertAction(video: videoToShare))
            self.present(ratingController, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playVideoFromYT", let destVC = segue.destination as? YouTubeVideoPlayerVC, let videoURL = sender as? URL {
            destVC.videoURL = videoURL
        } else {
            print("Unknown segue: \(segue.identifier ?? "no id") or wrong destination: \(segue.destination)")
        }
    }
}

extension VideoSearchResultsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoResultCell", for: indexPath) as! VideoTableViewCell
        let video = videoResults[indexPath.row]
        cell.thumbnailImageView.image = video.thumbnail
        cell.titleLabel.text = video.title
        cell.titleLabel.backgroundColor = UIColor(white: 1, alpha: 0.75)
        cell.titleLabel.textColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
        return cell
    }
}

extension VideoSearchResultsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let watchURL = videoResults[indexPath.row].watchURL else {
            print("No videoURL for video \(videoResults[indexPath.row].id)")
            return
        }
        self.watchedVideoIndex = indexPath.row
        self.performSegue(withIdentifier: "playVideoFromYT", sender: watchURL)
    }
}
