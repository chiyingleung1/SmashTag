//
//  TweetTableViewController.swift
//  SmashTag
//
//  Created by Chi-Ying Leung on 4/17/17.
//  Copyright © 2017 Chi-Ying Leung. All rights reserved.
//

import UIKit
import Twitter

class TweetTableViewController: UITableViewController, UITextFieldDelegate {
    
    override func awakeFromNib() {
        searchText = RecentSearches.searches.first
    }
    
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == searchTextField {
            searchText = searchTextField.text
        }
        return true
    }
    
    var tweets = [Array<Twitter.Tweet>]() {
        didSet {
        }
    }

    var searchText: String? {
        didSet {
            guard let text = searchText else {
                return
            }
            searchTextField?.text = searchText
            searchTextField?.resignFirstResponder()
            tweets.removeAll()
            tableView.reloadData()
            lastTwitterRequest = nil
            searchForTweets()
            RecentSearches.add(text)
        }
    }
    
    // can not be private, otherwise subclass 'SmashTweetTVC' can not override
    func insertTweets(_ newTweets: [Twitter.Tweet]) {
        self.tweets.insert(newTweets, at: 0)
        self.tableView.insertSections([0], with: .fade)
    }
    
    private func twitterRequest() -> Twitter.Request? {
        if lastTwitterRequest == nil {
            if let query = searchText, !query.isEmpty {
                return Twitter.Request(search: "\(query) -filter:safe -filter:retweets", count: 100)
            }
        }
        return lastTwitterRequest?.newer
    }
    
    private var lastTwitterRequest: Twitter.Request?
    
    private func searchForTweets() {
        if let request = twitterRequest() {
            lastTwitterRequest = request
            request.fetchTweets { [weak self] newTweets in
                DispatchQueue.main.async {
                    if request == self?.lastTwitterRequest {
                        self?.insertTweets(newTweets)
                    }
                    
                }
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let imageButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(showImages))
        let tweetersButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(showTweeters))
        navigationItem.rightBarButtonItems = [tweetersButton, imageButton]
        
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControlEvents.valueChanged)
    }
    
    @objc private func handleRefresh(_ refreshControl: UIRefreshControl) {
        searchForTweets()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    @objc private func showImages() {
        performSegue(withIdentifier: "ShowTweetImages", sender: navigationItem.rightBarButtonItems?[1])
    }
    
    @objc private func showTweeters() {
        performSegue(withIdentifier: "Tweeters Mentioning Search Term", sender: navigationItem.rightBarButtonItems?[0])
    }
    

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tweets.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Tweet", for: indexPath)
        
        let tweet: Twitter.Tweet = tweets[indexPath.section][indexPath.row]
//        cell.textLabel?.text = tweet.text
//        cell.detailTextLabel?.text = tweet.user.name
        
        if let tweetCell = cell as? TweetTableViewCell {
            tweetCell.tweet = tweet
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
    }
    
    private var selectedTweet: Twitter.Tweet?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTweet = tweets[indexPath.section][indexPath.row]
        performSegue(withIdentifier: "ShowMentions", sender: selectedTweet)
    }

}

extension UIViewController {
    var contentViewController: UIViewController {
        
        var firstController = self
        
        if let tabBarController = self as? UITabBarController {
            firstController = tabBarController.viewControllers?[0] ?? self
        }
        
        if let navController = firstController as? UINavigationController {
            return navController.visibleViewController ?? self
        } else {
            return self
        }
    }
}

