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
    @IBOutlet weak var _btDone: UIBarButtonItem!
    
    private let tokenViewMinHeight: CGFloat = 40.0
    private let tokenViewMaxHeight: CGFloat = 150.0
    private let _tokenBackgroundColor = UIColor(red: 165/255, green: 165/255, blue: 165/255, alpha: 1)
    
    private var _isSearching = false
    private var _isAddNewTag = false
    private var _tags = [TagItem]()
    private var _selectedTags = [TagItem]()
    private var _filteredTags = [TagItem]()
    
    private let _tagCache = TagCache.instance
    private let _imageCache = ImageCache.instance
    
    private var _initialCommonTags = Set<TagEntity>()
    private var _images = [ImageEntity]()
    private var _notifiableOnCloseProtocol: NotifiableOnCloseProtocol?
    
    func setup(entities: [ImageEntity], notifiableOnCloseProtocol: NotifiableOnCloseProtocol?) -> Void {
        
        _notifiableOnCloseProtocol = notifiableOnCloseProtocol
        
        if entities.isEmpty {
            return
        }
        
        _images = entities
        
        _initialCommonTags = Set(entities[0].tags)
        
        for entity in entities {
            _initialCommonTags = _initialCommonTags.intersection(entity.tags)
        }
        
        _selectedTags = _initialCommonTags.map{TagItem(name: $0.name, id: $0.id)}
        
        var tags = _tagCache.userTags.toDictionary{ (item: TagEntity) -> Int64 in
            item.id
        }
        
        for item in _selectedTags {
            tags.removeValue(forKey: item.id)
        }
        
        _tags = tags.values.map{TagItem(name: $0.name, id: $0.id)}
        
        sortTagSource()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        configureTheme()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.separatorStyle = .singleLine
        
        onSelectedTagsChanged()
        
        tokenView.layoutIfNeeded()
        tokenView.dataSource = self
        tokenView.delegate = self
        tokenView.reloadData()
        tokenView.layer.cornerRadius = 10
        tokenView.textView.becomeFirstResponder()
    }
    
    private func configureTheme() -> Void {
        let theme = Settings.instance.theme
        navigationController?.navigationBar.barTintColor = theme.barTintColor
        navigationController?.navigationBar.tintColor = theme.tintColor
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : theme.titleTextColor]
        
    }

    @IBAction func onCancelClicked(_ sender: Any) {
        _notifiableOnCloseProtocol?.notifyOnClose()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDoneClicked(_ sender: Any) {

        let resultTags = _selectedTags.map{$0.toTagEntity()}

        for entity in _images {

            var currentTags = Set(entity.tags)
            currentTags.subtract(_initialCommonTags)

            var newTags = Array(currentTags)
            newTags.append(contentsOf: resultTags)
            entity.replaceTags(tags: newTags)
        }

        _imageCache.saveOrUpdate(entities: _images)

        _notifiableOnCloseProtocol?.notifyOnClose()
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Keyboard
    @objc func keyboardWillShow(_ notification: Notification) -> Void {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            tableView.contentInset = contentInsets
            tableView.scrollIndicatorInsets = contentInsets
        }
    }
    
    @objc func keyboardWillHide(_ notification: NotificationCenter) -> Void {
        tableView.contentInset = UIEdgeInsets.zero
        tableView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    func dismissKeyboard() -> Void {
        tokenView.resignFirstResponder()
        tokenView.endEditing(true)
    }
    
    // MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if _isSearching {
            if _isAddNewTag {
                return _filteredTags.count + 1;
            }
            return _filteredTags.count
        }
        return _tags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCellId", for: indexPath) as! NWSTokenViewCell
        
        if _isSearching {
            
            if _isAddNewTag && indexPath.row == 0 {
                let newTag = TagItem(name: tokenView.textView.text!, id: 0)
                cell.updateAttributedText(newTag)
            }
            else if _isAddNewTag {
                cell.updateTag(_filteredTags[indexPath.row - 1])
            }
            else{
                cell.updateTag(_filteredTags[indexPath.row])
            }
        }
        else {
            cell.updateTag(_tags[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) -> Void {
        _isSearching = false
        _isAddNewTag = false
        
        let cell = tableView.cellForRow(at: indexPath) as! NWSTokenViewCell
        _selectedTags.append(cell.tagItem)
        onSelectedTagsChanged()
        tokenView.textView.text = String.empty
        tokenView.reloadData()
        
        _tags = _tags.filter{$0.id != cell.tagItem.id}
        reloadAndSortTagSource()
    }
    
    // MARK: NWSTokenDataSource
    func numberOfTokensForTokenView(_ tokenView: NWSTokenView) -> Int {
        return _selectedTags.count
    }
    
    func insetsForTokenView(_ tokenView: NWSTokenView) -> UIEdgeInsets? {
        return UIEdgeInsetsMake(5, 5, 5, 5)
    }
    
    func titleForTokenViewLabel(_ tokenView: NWSTokenView) -> String? {
        return nil
    }
    
    func titleForTokenViewPlaceholder(_ tokenView: NWSTokenView) -> String? {
        return "Selet or Enter Tag"
    }
    
    func tokenView(_ tokenView: NWSTokenView, viewForTokenAtIndex index: Int) -> UIView? {
        let tag = _selectedTags[index]
        if let token = NWSImageToken.initWithTitle(tag.name){
            return token
        }
        
        return nil
    }
    
    // MARK: NWSTokenDelegate
    func tokenView(_ tokenView: NWSTokenView, didSelectTokenAtIndex index: Int) -> Void {
        let token = tokenView.tokenForIndex(index) as! NWSImageToken
        token.backgroundColor = UIColor.darkGray
    }
    
    func tokenView(_ tokenView: NWSTokenView, didDeselectTokenAtIndex index: Int) -> Void {
        let token = tokenView.tokenForIndex(index) as! NWSImageToken
        token.backgroundColor = _tokenBackgroundColor
    }
    
    func tokenView(_ tokenView: NWSTokenView, didDeleteTokenAtIndex index: Int) -> Void {
        
        if(index >= self._selectedTags.count) {
            return
        }
        
        let tag = _selectedTags[index]
        
        _selectedTags.remove(at: index)
        onSelectedTagsChanged()
        tokenView.reloadData()
        
        _tags.append(tag)
        reloadAndSortTagSource()
        
        tokenView.layoutIfNeeded()
        tokenView.textView.keyboardAppearance = .dark
        tokenView.textView.becomeFirstResponder()
    }
    
    func tokenView(_ tokenViewDidBeginEditing: NWSTokenView) -> Void {
    }
    
    func tokenViewDidEndEditing(_ tokenView: NWSTokenView) -> Void {
//        print(tokenView.textView.text)
    }
    
    func tokenView(_ tokenView: NWSTokenView, didChangeText text: String) -> Void {
        
        if(text.isEmpty()){
            _isSearching = false
            tableView.reloadData()
            return
        }
        
        searchTags(text)
    }
    
    func tokenView(_ tokenView: NWSTokenView, didEnterText text: String) -> Void {
//        print(text)
    }
    
    func tokenView(_ tokenView: NWSTokenView, contentSizeChanged size: CGSize)  -> Void {
        self.tokenViewHeightConstraint.constant = max(tokenViewMinHeight,min(size.height, self.tokenViewMaxHeight))
        self.view.layoutIfNeeded()
    }
    
    func tokenView(_ tokenView: NWSTokenView, didFinishLoadingTokens tokenCount: Int)  -> Void {
        
    }
    
    private func onSelectedTagsChanged() -> Void {
        _btDone.isEnabled = !_selectedTags.isEmpty
    }
    
    private func reloadAndSortTagSource() -> Void {
        sortTagSource()
        tableView.reloadData()
    }
    
    private func searchTags(_ text: String) -> Void {
        
        if(text.isEmpty()){
            return
        }
        
        _isAddNewTag = true
        _isSearching = true
        
        _filteredTags = []
        
        if let _ = _selectedTags.first(where: {$0.name == text}){
            _isAddNewTag = false
        }
        
        if(_tags.isEmpty){
            tableView.reloadData()
            return
        }
        
        _filteredTags = _tags.filter({ $0.name.range(of: text, options: .caseInsensitive) != nil })
        
        if let _ = _filteredTags.first(where: {$0.name == text}){
            _isAddNewTag = false
        }
        
        tableView.reloadData()
    }
    
    private func sortTagSource() -> Void {
        _tags.sort{$0.name > $1.name}
    }
}

final class TagItem {
    
    private(set) var name: String
    private(set) var id: Int64
    
    init(name: String, id: Int64) {
        self.name = name
        self.id = id
    }
    
    func toTagEntity() -> TagEntity {
        return TagEntity(id: id, name: name)
    }
}

final class NWSTokenViewCell: UITableViewCell {
    @IBOutlet weak var _tagName: UILabel!
    private(set) var tagItem: TagItem!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func updateTag(_ tag: TagItem) -> Void {
        tagItem = tag
        _tagName.text = tag.name
    }
    
    func updateAttributedText(_ tag: TagItem) -> Void {
        tagItem = tag
        
        let newTagText = "Add new tag: "
        let newTagTextRange = NSRange(location: 0, length: newTagText.count)
        let attributes = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16)]
        let prettyString = NSMutableAttributedString(string: newTagText + tag.name)
        prettyString.setAttributes(attributes, range: newTagTextRange)
        prettyString.addAttribute(NSAttributedStringKey.foregroundColor, value: Settings.instance.theme.newTagTextColor, range: newTagTextRange)
        
        _tagName.attributedText = prettyString
    }
}
