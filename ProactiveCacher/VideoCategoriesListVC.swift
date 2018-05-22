//
//  VideoCategoriesListVC.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 21/05/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit
import RealmSwift

class VideoCategoriesListVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    lazy var videoCategories = try! Realm().objects(VideoCategory.self).sorted(byKeyPath: "name")

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}

extension VideoCategoriesListVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videoCategories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCategoryCell", for: indexPath)
        cell.textLabel?.text = videoCategories[indexPath.row].name
        return cell
    }
}

extension VideoCategoriesListVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Category \(videoCategories[indexPath.row]) selected")
    }
}
