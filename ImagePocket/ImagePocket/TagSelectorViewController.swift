//
//  TagSelectorViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 8/27/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit

class TagSelectorViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NWSTokenDataSource, NWSTokenDelegate {

    @IBOutlet weak var tokenViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tokenView: NWSTokenView!
    let tokenViewMinHeight: CGFloat = 40.0
    let tokenViewMaxHeight: CGFloat = 150.0
    let tokenBackgroundColor = UIColor(red: 98.0/255.0, green: 203.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    
    var isSearching = false
    var contacts = [TagItem]()
    var selectedContacts = [TagItem(name: "sdfsdf")]
    var filteredContacts = [TagItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Adjust tableView offset for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        // TableView
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.separatorStyle = .singleLine
        
        // TokenView
        tokenView.layoutIfNeeded()
        tokenView.dataSource = self
        tokenView.delegate = self
        tokenView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDoneClicked(_ sender: Any) {
    }
    
    // MARK: Keyboard
    func keyboardWillShow(_ notification: Notification){
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            tableView.contentInset = contentInsets
            tableView.scrollIndicatorInsets = contentInsets
            
        }
    }
    
    func keyboardWillHide(_ notification: NotificationCenter){
        tableView.contentInset = UIEdgeInsets.zero
        tableView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    func dismissKeyboard() {
        tokenView.resignFirstResponder()
        tokenView.endEditing(true)
    }
    
    // MARK: Search Contacts
    func searchContacts(_ text: String) {
        filteredContacts = []
        
        if contacts.count > 0 {
            filteredContacts = contacts.filter({ (contact: TagItem) -> Bool in
                return contact.name.range(of: text, options: .caseInsensitive) != nil
            })
            
            self.isSearching = true
            self.tableView.reloadData()
        }
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            return filteredContacts.count
        }
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCellId", for: indexPath) as! NWSTokenViewExampleCell
        
        let currentContacts: [TagItem]!
        
        // Check if searching
        if isSearching {
            currentContacts = filteredContacts
        }
        else {
            currentContacts = contacts
        }
        
        // Load contact data
        let contact = currentContacts[(indexPath as NSIndexPath).row]
        cell.loadWithContact(contact)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath) as! NWSTokenViewExampleCell
//        cell.isSelected = false
//        
//        // Check if already selected
//        if !selectedContacts.contains(cell.contact)
//        {
//            cell.contact.isSelected = true
//            selectedContacts.append(cell.contact)
//            isSearching = false
//            tokenView.textView.text = ""
//            tokenView.reloadData()
//            tableView.reloadData()
//        }
    }
    
    // MARK: NWSTokenDataSource
    func numberOfTokensForTokenView(_ tokenView: NWSTokenView) -> Int {
        return selectedContacts.count
    }
    
    func insetsForTokenView(_ tokenView: NWSTokenView) -> UIEdgeInsets? {
        return UIEdgeInsetsMake(5, 5, 5, 5)
    }
    
    func titleForTokenViewLabel(_ tokenView: NWSTokenView) -> String? {
        return nil
    }
    
    func titleForTokenViewPlaceholder(_ tokenView: NWSTokenView) -> String? {
        return "Enter a tag name"
    }
    
    func tokenView(_ tokenView: NWSTokenView, viewForTokenAtIndex index: Int) -> UIView? {
        let contact = selectedContacts[index]
        if let token = NWSImageToken.initWithTitle(contact.name){
            return token
        }
        
        return nil
    }
    
    // MARK: NWSTokenDelegate
    func tokenView(_ tokenView: NWSTokenView, didSelectTokenAtIndex index: Int) {
        let token = tokenView.tokenForIndex(index) as! NWSImageToken
        token.backgroundColor = UIColor.blue
    }
    
    func tokenView(_ tokenView: NWSTokenView, didDeselectTokenAtIndex index: Int) {
        let token = tokenView.tokenForIndex(index) as! NWSImageToken
        token.backgroundColor = tokenBackgroundColor
    }
    
    func tokenView(_ tokenView: NWSTokenView, didDeleteTokenAtIndex index: Int) {
        
        if(index >= self.selectedContacts.count) {
            return
        }
        
        self.selectedContacts.remove(at: index)
            
        tokenView.reloadData()
        tableView.reloadData()
        tokenView.layoutIfNeeded()
        tokenView.textView.becomeFirstResponder()
    }
    
    func tokenView(_ tokenViewDidBeginEditing: NWSTokenView) {
    }
    
    func tokenViewDidEndEditing(_ tokenView: NWSTokenView) {
        print(tokenView.textView.text)
    }
    
    func tokenView(_ tokenView: NWSTokenView, didChangeText text: String){
        print(text)
    }
    
    func tokenView(_ tokenView: NWSTokenView, didEnterText text: String) {
        print(text)
    }
    
    func tokenView(_ tokenView: NWSTokenView, contentSizeChanged size: CGSize)
    {
        self.tokenViewHeightConstraint.constant = max(tokenViewMinHeight,min(size.height, self.tokenViewMaxHeight))
        self.view.layoutIfNeeded()
    }
    
    func tokenView(_ tokenView: NWSTokenView, didFinishLoadingTokens tokenCount: Int){
        
    }
}

final class TagItem {
    
    private(set) var name: String!
    
    init(name: String) {
        self.name = name
    }
}

final class NWSTokenViewExampleCell: UITableViewCell {
    @IBOutlet weak var userTitleLabel: UILabel!
    
    var contact: TagItem!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func loadWithContact(_ contact: TagItem) {
        self.contact = contact
        userTitleLabel.text = contact.name
    }
}
