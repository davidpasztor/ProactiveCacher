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
        /*
        // Check it the video has already been downloaded or not
        let fileMetadata = fileMetadatas[indexPath.row]
        let realm = try! Realm()
        // If the video is already cached, load it from the local storage
        var video:Video
        if let fetchedVideo = realm.object(ofType: Video.self, forPrimaryKey: fileMetadata.id) {
            video = fetchedVideo
        } else {
            video = Video()
            video.name = fileMetadata.name
            video.fileID = fileMetadata.id
        }
        if let videoURLString = video.filePath, let videoURL = URL(string: videoURLString) {
            self.playVideo(from: videoURL)
        } else {
            activityIndicator.startAnimating()
            BoxAPI.shared.downloadFile(with: fileMetadata, completion: { fileURL, error in
                guard let fileURL = fileURL, error == nil else {
                    DispatchQueue.main.async {
                        self.activityIndicator.stopAnimating()
                    }
                    print(error ?? "Unknown error while downloading file"); return
                }
                DispatchQueue.main.async {
                    let realm = try! Realm()
                    do {
                        try realm.write {
                            video.filePath = fileURL.absoluteString
                        }
                    } catch {
                        print(error)
                    }
                    realm.saveOrUpdate(object: video)
                    self.activityIndicator.stopAnimating()
                    self.playVideo(from: fileURL)
                }
            })
        }
        */
        /*
        BoxAPI.shared.getEmbedLink(for: fileMetadatas[indexPath.row].id, completion: { embedUrl, error in
            guard let embedUrl = embedUrl, error == nil else {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                print(error ?? "Unknown error while getting embed URL"); return
            }
            print(embedUrl)
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.playVideo(from: embedUrl)
            }
        })
        */
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
