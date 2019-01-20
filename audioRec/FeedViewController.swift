//
//  FeedViewController.swift
//  audioRec
//
//  Created by Michael Roundcount on 7/31/18.
//  Copyright © 2018 Michael Roundcount. All rights reserved.
//

import UIKit
import AWSS3
import AVFoundation

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, DonePlayingDelegate, CustomCellUpdater {
    
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if(searchController.searchBar.text!.count > 0){
            print("search text:\(searchController.searchBar.text!)")
            filteredArray = activeTags.filter({ (NSMutableArray) -> Bool in
                if activeTags.contains(searchController.searchBar.text!) {
                    return true
                } else {
                    return false
                }
            }) as? NSMutableArray
            resultsController.tableView.reloadData()
        }

    }
    
    
    @IBOutlet weak var feedNavBtn: UIBarButtonItem!
    @IBOutlet weak var recorderNavBtn: UIBarButtonItem!
    @IBOutlet weak var profileNavBtn: UIBarButtonItem!
    
    var activeTags : NSMutableArray = []
    var searchText : String = ""
    var filteredArray : NSMutableArray?

    @IBAction func recorderNavBtn(_ sender: UIBarButtonItem) {
        print("recordd")
        s3Transfer.stopAudio()
        self.performSegue(withIdentifier: "feedToRecorder", sender: nil)
        
    }
    @IBAction func profileNavBtn(_ sender: UIBarButtonItem) {
        print("profile")
        s3Transfer.stopAudio()
        self.performSegue(withIdentifier: "feedToProfile", sender: nil)
    }
    
    var postCell: PostTableViewCell!
    let s3Transfer = S3TransferUtility()
    var token = ""
    var usernameString = ""
    let preferences = UserDefaults.standard
    var audioPlayer: AVAudioPlayer!
    
    var searchController = UISearchController()
    var resultsController = UITableViewController()
    var likedPosts : NSMutableArray = []
    
    @IBOutlet weak var tableView: UITableView!
    
    var posts : NSArray?

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == resultsController.tableView {
            return filteredArray!.count
        } else {
            return (posts?.count)!
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : PostTableViewCell!
 
        if((posts?.count)! > 0){
            
            let post = posts?[indexPath.row] as? [String: Any]
            let description = post!["description"] as? String
            let postID = post!["post_i_d"] as? Int
            let likes = post!["likes"] as? Int
            let username = post!["username"] as? String
            let timeCreated = post!["time_created"] as? Int
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM-dd-YYYY"
            let date = NSDate(timeIntervalSince1970: TimeInterval(timeCreated!))
            let finalDate = dateFormatter.string(from: date as Date)
            
            
            cell = tableView.dequeueReusableCell(withIdentifier: "feedTableViewCell") as! PostTableViewCell
            cell.postDescription.text = description!
            cell.usernameLabel.text = "By: \(username!)"
            cell.datePostedLabel.text = finalDate
            cell.postID = postID!
            cell.likes = likes!
            cell.token = self.token
            
            if((likedPosts.contains(postID))){
                cell.likeBtn.isEnabled = false
                cell.likeBtn.setTitle("Liked", for: .normal)
                cell.likeBtn.setTitleColor(#colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), for: .normal)
            } else {
                cell.likeBtn.isEnabled = true
                cell.likeBtn.setTitle("Like", for: .normal)
                cell.likeBtn.setTitleColor(#colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), for: .normal)
            }
        }
        cell.sizeToFit()
        //Cell Styling
        cell.contentView.backgroundColor = UIColor.clear
        let whiteRoundedView : UIView = UIView(frame: CGRect(x: 10, y: 8, width: self.view.frame.size.width - 20, height: self.view.frame.size.height))
        whiteRoundedView.layer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1.0, 1.0, 1.0, 0.9])
        whiteRoundedView.layer.masksToBounds = false
        whiteRoundedView.layer.cornerRadius = 2.0
        whiteRoundedView.layer.shadowOffset = CGSize(width: -1, height: 1)
        whiteRoundedView.layer.shadowOpacity = 0.2
        
        cell.contentView.addSubview(whiteRoundedView)
        cell.contentView.sendSubview(toBack: whiteRoundedView)
        
        func change() {
            cell.contentView.backgroundColor = UIColor.orange
        }
        
        cell.delegate = self
        
        return cell
    }
    
    
    func updateTableView() {
        
        getPosts()
        tableView.reloadData()
        print("updating tblviewcell")
        
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        postCell = tableView.cellForRow(at: indexPath) as! PostTableViewCell

        if audioPlayer != nil {
            if audioPlayer.isPlaying {
                audioPlayer.stop()
            }
        }
        
        if(activeTags.contains(indexPath.row)){
            print("is active cell, stopping audio")
            s3Transfer.stopAudio()
            activeTags.remove(indexPath.row)
        }
        else{
            let postID = postCell.postID!
            
            if audioPlayer != nil {
                if audioPlayer.isPlaying {
                    audioPlayer.stop()
                }
            }
            
            downloadAudioFromS3(postID: postID)
            postCell.contentView.backgroundColor = UIColor.green
            activeTags.add(indexPath.row)
        }
    }

    func downloadAudioFromS3(postID: Int) {
        s3Transfer.downloadData(postID: postID)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        feedNavBtn.isEnabled = false
        
        searchController = UISearchController(searchResultsController: resultsController)
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchResultsUpdater = self
        
        resultsController.tableView.delegate = self
        resultsController.tableView.dataSource = self
    
        self.tableView.dataSource = self
        self.tableView.delegate = self
        s3Transfer.delegate = self
        
        // get token from preferences
        if preferences.value(forKey: "tokenKey") == nil {
            //  Doesn't exist
        } else {
            self.token = preferences.value(forKey: "tokenKey") as! String
        }
        
        // get token from preferences
        if preferences.value(forKey: "username") == nil {
            //  Doesn't exist
        } else {
            self.usernameString = preferences.value(forKey: "username") as! String
        }
        
        getPosts()
        
    }
    
    func getPosts(){
        let dbManager = DatabaseManager()
        let dataString = "{\"Username\":[{\"username\":\"" + self.usernameString + "\"}]}"
        
        self.posts = dbManager.getPostsForFeed(token: self.token, data: dataString) as NSArray
        self.posts = self.posts!.reversed() as NSArray
        print("Posts: \(posts)")
        let array = dbManager.getLikedPosts(token: self.token) as NSArray
        
        for (index, element) in array.enumerated() {
            let post = array[index] as? [String: Any]
            let postID = post!["post_i_d"] as? Int
            likedPosts.add(postID)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func donePlayingAudio(){
        postCell.contentView.backgroundColor = UIColor.clear
    }
}



