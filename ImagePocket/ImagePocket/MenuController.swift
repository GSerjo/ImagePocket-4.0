//
//  MenuController.swift
//  ImagePocket
//
//  Created by Serjo on 23/10/16.
//  Copyright © 2016 Serjo. All rights reserved.
//

import UIKit

class MenuController: UITableViewController {

    private let _tagCache = TagCache.instance
    private(set) var selectedTag: TagEntity?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTag = _tagCache.allTags[indexPath.row]
        sideMenuController?.performSegue(withIdentifier: "showCenterController", sender: nil)
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return _tagCache.allTags.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
        cell.textLabel?.text = _tagCache.allTags[indexPath.row].name

        return cell
    }
}
