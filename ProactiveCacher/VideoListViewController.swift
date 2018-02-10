//
//  VideoListViewController.swift
//  ProactiveCacher
//
//  Created by Pásztor Dávid on 10/02/2018.
//  Copyright © 2018 Pásztor Dávid. All rights reserved.
//

import UIKit

class VideoListViewController: UITableViewController {
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    var fileIDs = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.frame.height/5
        tableView.rowHeight = UITableViewAutomaticDimension
        addActivityIndicator(activityIndicator: activityIndicator, view: self.view)
        activityIndicator.startAnimating()
        if let jwtToken = BoxAPI.shared.generateJWTToken(isEnterprise: false, userId: BoxAPI.shared.sharedUserId) {
            BoxAPI.shared.getOAuth2Token(using: jwtToken, completion: { oAuthToken, expiryDate, error in
                guard let oAuthToken = oAuthToken, let expiryDate = expiryDate, error == nil else {
                    print(error?.localizedDescription ?? "No error");return
                }
                print("OAuthToken: \(oAuthToken), expires at : \(expiryDate)")
                BoxAPI.shared.accessToken = oAuthToken
                BoxAPI.shared.getFolderInfo(completion: { metadataForFiles, error in
                    guard let metadataForFiles = metadataForFiles, error == nil else {
                        print(error ?? "Unknown error");return
                    }
                    print(metadataForFiles)
                    self.fileIDs = metadataForFiles.map{$0.id}
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                        self.activityIndicator.stopAnimating()
                    }
                })
            })
        } else {
            print("No JWT token")
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileIDs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! VideoTableViewCell
        let cellDownloadIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        addActivityIndicator(activityIndicator: cellDownloadIndicator, view: cell.contentView)
        cellDownloadIndicator.startAnimating()
        BoxAPI.shared.createThumbnail(for: fileIDs[indexPath.row], completion: { thumbnail, error in
            guard let thumbnail = thumbnail else {
                DispatchQueue.main.async {
                    cellDownloadIndicator.stopAnimating()
                }
                print(error ?? "Unknown error"); return
            }
            DispatchQueue.main.async {
                // TODO: need to fix the cell height
                cell.thumbnailImageView.image = thumbnail
                cellDownloadIndicator.stopAnimating()
            }
        })
        return cell
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
