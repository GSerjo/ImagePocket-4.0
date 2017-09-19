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
    private let _sectionName = ["Tags", "Settings"]
    private var _allTags = [TagEntity]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _allTags = _tagCache.allTags
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTag = _allTags[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: false)
        sideMenuController?.toggle()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return _allTags.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuCell", for: indexPath)
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = _allTags[indexPath.row].name
        default:
            cell.textLabel?.text = "Test"
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return _sectionName[section]
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        (view as! UITableViewHeaderFooterView).backgroundView?.backgroundColor = UIColor.darkGray.withAlphaComponent(0.4)
    }
    
    func didReveal() -> Void {
        _allTags = _tagCache.allTags
        tableView.reloadData()
    }
}
