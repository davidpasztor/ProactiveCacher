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
class VideoSearchResultsVC: UIViewController {
    
    @IBOutlet weak var searchResultsTable: UITableView!
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var videoResults = [YouTubeVideo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchResultsTable.delegate = self
        searchResultsTable.dataSource = self
        UIViewController.addActivityIndicator(activityIndicator: activityIndicator, view: self.view)
        searchResultsTable.rowHeight = searchResultsTable.frame.width/16*9
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
        // TODO: should probably be moved to the VideoTableViewCell class, since now these 2 lines need to be called on both this VC and VideoListViewController
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
        self.performSegue(withIdentifier: "playVideoFromYT", sender: watchURL)
    }
}
