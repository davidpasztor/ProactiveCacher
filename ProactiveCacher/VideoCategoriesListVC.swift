//
//  VideoCategoriesListVC.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 21/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit
import RealmSwift
import SideMenuSwift

class VideoCategoriesListVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var realm = try! Realm()
    lazy var videoCategories = realm.objects(VideoCategory.self).sorted(byKeyPath: "name")
    var selectedCategory: VideoCategory? = nil {
        didSet {
            if let navigationVC = sideMenuController?.contentViewController as? UINavigationController, let videoListVC = navigationVC.topViewController as? VideoListViewController {
                if let selectedCategory = selectedCategory {
                    print("Filtering videos for category \(selectedCategory.name)")
                    videoListVC.navigationItem.title = selectedCategory.name
                    videoListVC.videos = try! Realm().objects(Video.self).filter("category == %@",selectedCategory).sorted(by: VideoListViewController.videoSortDescriptors)
                } else {
                    print("Displaying all videos")
                    videoListVC.navigationItem.title = "All"
                    videoListVC.videos = try! Realm().objects(Video.self).sorted(by: VideoListViewController.videoSortDescriptors)
                }
                videoListVC.tableView.reloadData()
            } else {
                print("sideMenuController?.contentViewController is not UINavigationController or the topViewController is not VideoListViewController")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Even though the `videoCategories` `Results` is auto-updating, need to call `reloadData` to let the `tableView` know that its `dataSource` has changed
        tableView.reloadData()
    }
    
}

extension VideoCategoriesListVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Include an `All` category, which displays all Videos regardless of category
        return videoCategories.count+1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCategoryCell", for: indexPath)
        if indexPath.row == 0 {
            cell.textLabel?.text = "All"
        } else {
            cell.textLabel?.text = videoCategories[indexPath.row-1].name
        }
        return cell
    }
}

extension VideoCategoriesListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            print("Category all selected")
            selectedCategory = nil
        } else {
            print("Category \(videoCategories[indexPath.row-1]) selected")
            selectedCategory = videoCategories[indexPath.row-1]
        }
        sideMenuController?.hideMenu()
    }
}
