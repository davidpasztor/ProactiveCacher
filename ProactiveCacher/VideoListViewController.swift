//
//  VideoListViewController.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/02/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import RealmSwift
import Cosmos

class VideoListViewController: UITableViewController {
    
    @IBOutlet weak var uploadButton: UIBarButtonItem!
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    //var videos:Results<Video>?
    var videos = [Video]()
    var watchedVideoIndex: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        //Since the videos have to have a 16:9 ratio, the thumbnails should also
        tableView.rowHeight = CGFloat(tableView.frame.width)/16*9
        //Pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(VideoListViewController.loadVideos), for: .valueChanged)
        addActivityIndicator(activityIndicator: activityIndicator, view: self.view)
        // Check for server authorization, if the user is not registered yet, do the registration first
        if CacheServerAPI.shared.userID == nil {
            activityIndicator.startAnimating()
            CacheServerAPI.shared.registerUser(completion: { result in
                switch result {
                case .success(_):
                    self.loadVideos()
                case let .failure(error):
                    if case let CacheServerErrors.HTTPFailureResponse(statusCode, _) = error, statusCode == 401 {
                        CacheServerAPI.shared.userID = nil
                    }
                    print(error)
                }
                self.activityIndicator.stopAnimating()
            })
        } else {
            loadVideos()
        }
        UserDataLogger.shared.saveUserLog()
    }
    
    // Function for loading the list of videos
    @objc func loadVideos(){
        activityIndicator.startAnimating()
        CacheServerAPI.shared.getVideoList(completion: { result in
            switch result {
            case let .success(videos):
                self.videos = videos
                self.tableView.reloadData()
            case let .failure(error):
                print(error)
            }
            self.activityIndicator.stopAnimating()
            self.refreshControl?.endRefreshing()
        })
    }
    
    @IBAction func addVideo(_ sender: UIBarButtonItem) {
        let actionController = UIAlertController(title: "Upload new video", message: "Please provide the YouTube link for the video you would like to upload.", preferredStyle: .alert)
        actionController.addTextField(configurationHandler: { textfield in
            textfield.placeholder = "YouTube link of video"
        })
        let uploadAction = UIAlertAction(title: "Upload", style: .default, handler: { action in
            // Should validate that the URL is a YouTube URL of the correct form
            if let youtubeUrlString = actionController.textFields?.first?.text, let youtubeUrl = URL(string: youtubeUrlString){
                CacheServerAPI.shared.uploadVideo(with: youtubeUrl, completion: { result in
                    switch result {
                        case .success(_):
                            print("Upload successfully started!")
                        case let .failure(error):
                            print("Upload failed with error: \(error)")
                    }
                })
            } else {
                print("Invalid URL \(actionController.textFields?.first?.text ?? "")")
                //Present another controller with an error message
            }
        })
        actionController.addAction(uploadAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionController.addAction(cancelAction)
        self.present(actionController, animated: true, completion: nil)
    }
    
    /**
     Add an activity indicator to the specified view. Set Autolayout constraints to keep the indicator in the middle of the screen.
     - parameter activityIndicator: activityIndicator view to be added
     - parameter view: UIView to which the activity indicator should be added as a subview
    */
    func addActivityIndicator(activityIndicator: UIActivityIndicatorView,view:UIView){
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = UIColor.black
        let horizontalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(horizontalConstraint)
        let verticalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalConstraint)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     Play a video from the specified URL in an AVPlayerViewController. The URL can be both a local or remote URL. The viewcontroller with the video is presented from the main thread, so the function can safely be called from a background thread.
     - parameter url: URL representing the local or remote location of the video to be played
    */
    func playVideo(from url:URL){
        DispatchQueue.main.async {
            let playerController = AVPlayerViewController()
            playerController.player = AVPlayer(url: url)
            self.present(playerController, animated: true, completion: nil)
            playerController.view.frame = self.view.frame
            playerController.player?.play()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Present the rating view if the user was watching a video
        if let justWatchedVideoIndex = watchedVideoIndex {
            self.watchedVideoIndex = nil
            let starCount = 5
            let ratingView = CosmosView()
            ratingView.settings.minTouchRating = 0
            ratingView.settings.totalStars = starCount
            ratingView.settings.updateOnTouch = true
            ratingView.settings.fillMode = .half
            ratingView.settings.starMargin = 5
            ratingView.settings.starSize = Double(self.view.frame.width/5)-Double(starCount)*ratingView.settings.starMargin
            ratingView.settings.emptyImage = UIImage(named: "GoldStarEmpty")
            ratingView.settings.filledImage = UIImage(named: "GoldStar")
            ratingView.didFinishTouchingCosmos = { rating in
                self.videos[justWatchedVideoIndex].rating.value = rating
            }
            // Set the custom view to a fixed height. In a real world application, you could use autolayouted content for height constraints
            ratingView.translatesAutoresizingMaskIntoConstraints = false
            ratingView.addConstraint(NSLayoutConstraint(item: ratingView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: CGFloat(ratingView.settings.starSize)))
            
            // Create the alert and show it
            let ratingController = UIAlertController(title: "Please rate the video you just watched", customView: ratingView, fallbackMessage: "This should be a cosmos view", preferredStyle: .actionSheet)
            /*
            let totalMargin = Double(starCount+1)*ratingView.settings.starMargin
            ratingView.frame.origin.x = (ratingController.view.frame.width - (CGFloat(starCount)*CGFloat(ratingView.settings.starSize+totalMargin)))/2
            */
            ratingController.addAction(UIAlertAction(title: "Done", style: .default, handler: { action in
                let video = self.videos[justWatchedVideoIndex]
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
                    print("Done pushed without chosing a rating")
                }
            }))
            ratingController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            self.present(ratingController, animated: true, completion: nil)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! VideoTableViewCell
        let cellDownloadIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        addActivityIndicator(activityIndicator: cellDownloadIndicator, view: cell.contentView)
        // Check it the video has already been downloaded or not
        let videoMetadata = videos[indexPath.row]
        let realm = try! Realm()
        // If the video is already cached, load its thumbnail from the local storage
        var video:Video
        if let fetchedVideo = realm.object(ofType: Video.self, forPrimaryKey: videoMetadata.youtubeID) {
            video = fetchedVideo
            if let thumbnailPath = video.thumbnailPath {
                cell.thumbnailImageView.image = UIImage(contentsOfFile: thumbnailPath)
                return cell // early return to prevent the thumbnail download from happening
            }
        } else {
            video = Video()
            video.title = videoMetadata.title
            video.youtubeID = videoMetadata.youtubeID
        }
        cell.titleLabel.text = video.title
        cellDownloadIndicator.startAnimating()
        CacheServerAPI.shared.getThumbnail(for: video.youtubeID, completion: { result in
            if case let .success(thumbnailData) = result {
                cell.thumbnailImageView.image = UIImage(data: thumbnailData)
            } else if case let .failure(error) = result {
                print(error)
            }
            cellDownloadIndicator.stopAnimating()
        })
        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoMetadata = videos[indexPath.row]
        let realm = try! Realm()
        var video:Video
        if let fetchedVideo = realm.object(ofType: Video.self, forPrimaryKey: videoMetadata.youtubeID) {
            video = fetchedVideo
            if let filePathString = video.filePath, let filePath = URL(string: filePathString) {
                self.playVideo(from: filePath)
            }
        } else {
            video = Video()
            video.title = videoMetadata.title
            video.youtubeID = videoMetadata.youtubeID
            let streamUrlString = "\(CacheServerAPI.shared.baseURL)/stream?videoID=\(video.youtubeID)&user=\(CacheServerAPI.shared.userID!)"
            guard let streamURL = URL(string: streamUrlString) else {
                print("Invalid streamURL: \(streamUrlString)"); return
            }
            self.watchedVideoIndex = indexPath.row
            self.playVideo(from: streamURL)
        }
    }

}

//: [Add custom views to actionsheet in UIAlertController](https://stackoverflow.com/questions/32790207/uialertcontroller-add-custom-views-to-actionsheet/47925120#47925120)
extension UIAlertController {
    
    /// Creates a `UIAlertController` with a custom `UIView` instead the message text.
    /// - Note: In case anything goes wrong during replacing the message string with the custom view, a fallback message will
    /// be used as normal message string.
    ///
    /// - Parameters:
    ///   - title: The title text of the alert controller
    ///   - customView: A `UIView` which will be displayed in place of the message string.
    ///   - fallbackMessage: An optional fallback message string, which will be displayed in case something went wrong with inserting the custom view.
    ///   - preferredStyle: The preferred style of the `UIAlertController`.
    convenience init(title: String?, customView: UIView, fallbackMessage: String?, preferredStyle: UIAlertControllerStyle) {
        
        let marker = "__CUSTOM_CONTENT_MARKER__"
        self.init(title: title, message: marker, preferredStyle: preferredStyle)
        
        // Try to find the message label in the alert controller's view hierarchie
        if let customContentPlaceholder = self.view.findLabel(withText: marker),
            let customContainer =  customContentPlaceholder.superview {
            
            // The message label was found. Add the custom view over it and fix the autolayout...
            customContainer.addSubview(customView)
            
            customView.translatesAutoresizingMaskIntoConstraints = false
            customContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[customView]-|", options: [], metrics: nil, views: ["customView": customView]))
            customContainer.addConstraint(NSLayoutConstraint(item: customContentPlaceholder, attribute: .top, relatedBy: .equal, toItem: customView, attribute: .top, multiplier: 1, constant: 0))
            customContainer.addConstraint(NSLayoutConstraint(item: customContentPlaceholder, attribute: .height, relatedBy: .equal, toItem: customView, attribute: .height, multiplier: 1, constant: 0))
            customContentPlaceholder.text = ""
        } else { // In case something fishy is going on, fall back to the standard behaviour and display a fallback message string
            self.message = fallbackMessage
        }
    }
}

private extension UIView {
    
    /// Searches a `UILabel` with the given text in the view's subviews hierarchy.
    ///
    /// - Parameter text: The label text to search
    /// - Returns: A `UILabel` in the view's subview hierarchy, containing the searched text or `nil` if no `UILabel` was found.
    func findLabel(withText text: String) -> UILabel? {
        if let label = self as? UILabel, label.text == text {
            return label
        }
        for subview in self.subviews {
            if let found = subview.findLabel(withText: text) {
                return found
            }
        }
        return nil
    }
}
