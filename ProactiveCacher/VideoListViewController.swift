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
import MediaPlayer

class VideoListViewController: UITableViewController, RatingControllerDelegate {
    
    @IBOutlet weak var uploadButton: UIBarButtonItem!
    @IBOutlet weak var categoriesButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    // Keep the cached videos on top of the list and sort the non-cached videos based on their uploadDate property
    // descending sorting keeps the videos whose filePath is non-nil on top and 
    static let videoSortDescriptors = [SortDescriptor(keyPath: "filePath", ascending: false),SortDescriptor(keyPath: "uploadDate", ascending: false)]
    lazy var videos = try! Realm().objects(Video.self).sorted(by: VideoListViewController.videoSortDescriptors)
    var watchedVideoIndex: Int? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        //Since the videos have to have a 16:9 ratio, the thumbnails should also
        tableView.rowHeight = CGFloat(tableView.frame.width)/16*9
        //Pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl?.addTarget(self, action: #selector(VideoListViewController.loadVideos), for: .valueChanged)
        UIViewController.addActivityIndicator(activityIndicator: activityIndicator, view: self.view)
        loadVideos()
        //TODO: could probably be moved to AppDelegate
        UserDataLogger.shared.saveUserLog()
        // Upload UserLogs to the server
        let realm = try! Realm()
        let userLogs = realm.objects(UserLog.self).filter("syncedToBackend == false")
        CacheServerAPI.shared.uploadUserLogs(Array(userLogs), completion: { result in
            switch result {
            case .success(_):
                try! realm.write {
                    userLogs.forEach({$0.syncedToBackend = true})
                }
            case let .failure(error):
                print("Error uploading userlogs: ",error)
            }
        })
        // Delete cached videos if they are older than a threshold
        let videoAgeThreshold = DateComponents(day: -2)
        let oldCachedVideos = videos.filter("filePath != nil AND uploadDate < %@",Calendar.current.date(byAdding: videoAgeThreshold, to: Date())!)
        for video in oldCachedVideos {
            do {
                try realm.write {
                    if (video.watched) {
                        AppUsageLog.current.watchedCachedVideosCount += 1
                    } else {
                        AppUsageLog.current.notWatchedCachedVideosCount += 1
                    }
                    video.filePath = nil
                    video.thumbnailPath = nil
                }
                if let videoUrl = video.absoluteFileURL {
                    try FileManager.default.removeItem(at: videoUrl)
                }
                if let thumbnailUrl = video.absoluteThumbnailURL {
                    try FileManager.default.removeItem(at: thumbnailUrl)
                }
                print("Deleted cached file for video \(video.youtubeID) that was cached at \(video.uploadDate)")
            } catch {
                print("Error while deleting cached video: ",error)
            }
        }
        //Remove categories that have no videos
        try! realm.write {
            realm.delete(realm.objects(VideoCategory.self).filter("videos.@count == 0"))
        }
    }
    
    @IBAction func browseCategories(_ sender: UIBarButtonItem) {
        sideMenuController?.revealMenu()
    }
    
    // Function for loading the list of videos
    @objc func loadVideos(){
        activityIndicator.startAnimating()
        CacheServerAPI.shared.getVideoList(completion: { result in
            switch result {
            case let .success(videosFromServer):
                let realm = try! Realm()
                // Only add videos to Realm that weren't already added in order to avoid overwriting already cached videos
                let newVideos = videosFromServer.filter({videoFromServer in self.videos.filter("youtubeID == %@",videoFromServer.youtubeID).count == 0})
                // Delete videos from the device that were deleted from the server
                let videosToDelete = self.videos.filter("NOT youtubeID IN %@", videosFromServer.map{$0.youtubeID})
                for video in videosToDelete {
                    if let videoURL = video.absoluteFileURL {
                        do {
                            print("Deleting cached video file for video \(video.youtubeID)")
                            try FileManager.default.removeItem(at: videoURL)
                        } catch {
                            print("Error deleting cached video file for video \(video.youtubeID): \(error)")
                        }
                    }
                    if let thumbnailURL = video.absoluteThumbnailURL {
                        do {
                            print("Deleting cached thumbnail image for video \(video.youtubeID)")
                            try FileManager.default.removeItem(at: thumbnailURL)
                        } catch {
                            print("Error deleting cached thumbnail image for video \(video.youtubeID): \(error)")
                        }
                    }
                }
                let categories = newVideos.compactMap({$0.category})
                try! realm.write {
                    realm.add(categories,update:true)
                    realm.add(newVideos, update: true)
                    realm.delete(videosToDelete)
                    // Update existing videos that had no category associated with them
                    for videoWithNoCategory in realm.objects(Video.self).filter("category == nil") {
                        videoWithNoCategory.category = videosFromServer.first(where: {$0.youtubeID == videoWithNoCategory.youtubeID})?.category
                    }
                }
                self.tableView.reloadData()
            case let .failure(error):
                print("Error loading videos: ",error)
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
                            print("Video upload successfully started!")
                            let successController = UIAlertController(title: "Success", message: "Video successfully shared!", preferredStyle: .alert)
                            successController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(successController, animated: true, completion: nil)
                        case let .failure(error):
                            print("Video upload failed with error: \(error)")
                            let errorController = UIAlertController(title: "Error", message: "Video couldn't be shared, please make sure you have an active internet connection and that the URL you supply is a valid Youtube URL.", preferredStyle: .alert)
                            errorController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(errorController, animated: true, completion: nil)
                    }
                })
            } else {
                print("Invalid URL \(actionController.textFields?.first?.text ?? "")")
                //Present another controller with an error message
                let errorController = UIAlertController(title: "Invalid URL", message: "Please make sure you supply a valid Youtube URL.", preferredStyle: .alert)
                errorController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(errorController, animated: true, completion: nil)
            }
        })
        actionController.addAction(uploadAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionController.addAction(cancelAction)
        self.present(actionController, animated: true, completion: nil)
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
            //playerController.updatesNowPlayingInfoCenter = false
            playerController.view.frame = self.view.frame
            playerController.player?.play()
            //self.setNowPlayingInfo(to: self.videos[self.watchedVideoIndex!])
        }
    }
    
    /**
     Set information to display on the lock screen when playing a video in the background
     */
    func setNowPlayingInfo(to currentlyPlayedVideo:Video){
        print("Setting nowPlayingInfo")
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentlyPlayedVideo.title
        
        if let absoluteThumbnailUrl = currentlyPlayedVideo.absoluteThumbnailURL {
            let artworkImage = UIImage(contentsOfFile: absoluteThumbnailUrl.path) ?? UIImage()
            let artwork = MPMediaItemArtwork(boundsSize: artworkImage.size, requestHandler: {  (_) -> UIImage in
                return artworkImage
            })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        print(nowPlayingInfo)
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Present the rating view if the user was watching a video
        if let justWatchedVideoIndex = watchedVideoIndex {
            self.watchedVideoIndex = nil
            try! Realm().write {
                self.videos[justWatchedVideoIndex].watched = true
            }
            let presentingView = transformPresentingView(self.view)
            let ratingView = createRatingView(fitting: presentingView)
            ratingView.didFinishTouchingCosmos = { rating in
                do {
                    let realm = try Realm()
                    try realm.write {
                        self.videos[justWatchedVideoIndex].rating.value = rating
                    }
                } catch {
                    print("Error updating rating for \(self.videos[justWatchedVideoIndex])")
                }
            }
            // Create the alert and show it
            let ratingController = alertControllerForRating(embedding: ratingView, presentingView: presentingView)
            ratingController.addAction(doneRatingAlertAction(for: self.videos[justWatchedVideoIndex]))
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
        UIViewController.addActivityIndicator(activityIndicator: cellDownloadIndicator, view: cell.contentView)
        // Check if the video has already been downloaded or not
        let videoMetadata = videos[indexPath.row]
        let realm = try! Realm()
        var video:Video
        if let fetchedVideo = realm.object(ofType: Video.self, forPrimaryKey: videoMetadata.youtubeID) {
            video = fetchedVideo
        } else {
            video = Video()
            video.title = videoMetadata.title
            video.youtubeID = videoMetadata.youtubeID
        }
        //print("Video filePath: \(video.filePath ?? ""), thumbnailPath: \(video.thumbnailPath ?? "")")
        if video.filePath != nil {
            cell.titleLabel.text = "\(video.title) ✅"
        } else {
            cell.titleLabel.text = video.title
        }
        cell.titleLabel.backgroundColor = UIColor(white: 1, alpha: 0.75)
        cell.titleLabel.textColor = UIColor(red: 33/255, green: 33/255, blue: 33/255, alpha: 1)
        // If the video is already cached, load its thumbnail from the local storage
        if let absoluteThumbnailUrl = video.absoluteThumbnailURL {
            cell.thumbnailImageView.image = UIImage(contentsOfFile: absoluteThumbnailUrl.path)
        } else {
            // Otherwise load it from the server
            cellDownloadIndicator.startAnimating()
            CacheServerAPI.shared.getThumbnail(for: video.youtubeID, completion: { result in
                if case let .success(thumbnailData) = result {
                    cell.thumbnailImageView.image = UIImage(data: thumbnailData)
                    // Cache the thumbnail
                    do {
                        let thumbnailsDirectory = try FileManager.default.thumbnailsDirectory()
                        let relativeThumbnailPath = "\(video.youtubeID).jpg"
                        try thumbnailData.write(to: thumbnailsDirectory.appendingPathComponent(relativeThumbnailPath))
                        try realm.write {
                            video.thumbnailPath = relativeThumbnailPath
                        }
                    } catch {
                        print("Error caching thumbnail: \(error)")
                    }
                } else if case let .failure(error) = result {
                    print("Error getting video thumbnail: ",error)
                }
                cellDownloadIndicator.stopAnimating()
            })
        }
        return cell
    }
    
    // MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let videoMetadata = videos[indexPath.row]
        let realm = try! Realm()
        try! realm.write {
            AppUsageLog.current.watchedVideosCount += 1
        }
        var video:Video
        if let fetchedVideo = realm.object(ofType: Video.self, forPrimaryKey: videoMetadata.youtubeID) {
            video = fetchedVideo
        } else {
            video = Video()
            video.title = videoMetadata.title
            video.youtubeID = videoMetadata.youtubeID
        }
        // If video is already cached, play it from local path
        if let absoluteFileURL = video.absoluteFileURL {
            self.watchedVideoIndex = indexPath.row
            self.setNowPlayingInfo(to: video)
            self.playVideo(from: absoluteFileURL)
        } else {
            //Otherwise stream it from the server
            let streamUrlString = "\(CacheServerAPI.shared.baseURL)/stream?videoID=\(video.youtubeID)&user=\(CacheServerAPI.shared.userID!)"
            guard let streamURL = URL(string: streamUrlString) else {
                print("Invalid streamURL: \(streamUrlString)"); return
            }
            self.watchedVideoIndex = indexPath.row
            self.setNowPlayingInfo(to: video)
            self.playVideo(from: streamURL)
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchResults", let destVC = segue.destination as? VideoSearchResultsVC, let matchingVideos = sender as? [YouTubeVideo] {
            destVC.videoResults = matchingVideos
        } else {
            print("Unknown segue: \(segue.identifier ?? "no id") or wrong destination: \(segue.destination)")
        }
    }
}

extension VideoListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        YouTubeAPI.shared.searchVideos(keyword: searchBar.text!, in: nil, completion: { result in
            searchBar.text = ""
            switch result {
            case let .failure(error):
                print(error)
            case let .success(matchingVideos):
                self.performSegue(withIdentifier: "showSearchResults", sender: matchingVideos)
            }
        })
        searchBar.resignFirstResponder()
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
