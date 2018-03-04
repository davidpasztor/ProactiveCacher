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

class VideoListViewController: UITableViewController {
    
    @IBOutlet weak var uploadButton: UIBarButtonItem!
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    //var videos:Results<Video>?
    var videos = [Video]()

    override func viewDidLoad() {
        super.viewDidLoad()
        //Since the videos have to have a 16:9 ratio, the thumbnails should also
        tableView.rowHeight = CGFloat(tableView.frame.width)/16*9
        addActivityIndicator(activityIndicator: activityIndicator, view: self.view)
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
    
    func playVideo(from url:URL){
        DispatchQueue.main.async {
            let playerController = AVPlayerViewController()
            playerController.player = AVPlayer(url: url)
            self.present(playerController, animated: true, completion: nil)
            playerController.view.frame = self.view.frame
            playerController.player?.play()
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
        CacheServerAPI.shared.getThumbnail(for: video.youtubeID, completion: { result in
            if case let .success(thumbnailData) = result {
                cell.thumbnailImageView.image = UIImage(data: thumbnailData)
            } else if case let .failure(error) = result {
                print(error)
            }
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
            activityIndicator.startAnimating()
            CacheServerAPI.shared.streamVideo(with: video.youtubeID, completion: { result in
                switch result {
                case let .success(htmlString):
                    self.performSegue(withIdentifier: "streamVideoSegue", sender: htmlString)
                case let .failure(error):
                    print(error)
                }
                self.activityIndicator.stopAnimating()
            })
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "streamVideoSegue", let destination = segue.destination as? StreamedVideoVC, let htmlString = sender as? String {
            destination.streamHtmlString = htmlString
        }
    }

}
