//
//  TagsViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 12/10/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit

protocol TagsProtocol {
    func onSelectTag(tag: TagEntity) -> Void
}


class TagsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private var _tags = [TagEntity]()
    private var _settings = [SettingsItem]()
    private var _tagsProtocol: TagsProtocol!
    private var _removedTags = [Int64: TagEntity]()
    private var _editedTags = [Int64: TagEntity]()
    
    @IBOutlet weak var _btCancel: UIBarButtonItem!
    @IBOutlet weak var _btDone: UIBarButtonItem!
    @IBOutlet weak var _tableView: UITableView!
    
    enum TableSection: Int {
        case tags = 0, settings
        
        static var count: Int {
            return TableSection.settings.rawValue + 1
        }
    }
    
    private func configureTheme() -> Void {
        let theme = Settings.instance.theme
        navigationController?.navigationBar.barTintColor = theme.barTintColor
        navigationController?.navigationBar.tintColor = theme.tintColor
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : theme.titleTextColor]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTheme()
        enableOrDisableDone()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    public func setup(tags: [TagEntity], tagsProtocol: TagsProtocol) -> Void {
        _tags = tags
        _tagsProtocol = tagsProtocol
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDoneClicked(_ sender: Any) {
        ImageCache.instance.removeTagFromImages(tags: _removedTags.values.toArray())
        ImageCache.instance.updateTagFromImages(tags: _editedTags.values.toArray())
        dismiss(animated: true, completion: nil)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return TableSection.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let tableSection = TableSection(rawValue: section) {
            switch tableSection {
            case .tags:
                return _tags.count
            case .settings:
                return _settings.count
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagsCellId", for: indexPath) as! TagCell
        
        if let tableSection = TableSection(rawValue: indexPath.section) {
            switch tableSection {
            case .tags:
                cell._text.text = _tags[indexPath.item].name
            case .settings:
                cell._text.text = _settings[indexPath.item].text
            }
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) -> Void {
        if let tableSection = TableSection(rawValue: indexPath.section), tableSection == .tags {
            dismiss(animated: true, completion: nil)
            _tagsProtocol.onSelectTag(tag: _tags[indexPath.item])
        }
    }

    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let trashAction = UIContextualAction(style: .destructive, title: "Trash") { [unowned self] (action, view, completionHandler) in

            let tag = self._tags[indexPath.item]
            
            self._removedTags[tag.id] = tag
            self._editedTags.removeValue(forKey: tag.id)
            self._tags.remove(at: indexPath.item)

            self._tableView.beginUpdates()
            self._tableView.deleteRows(at: [indexPath], with: .automatic)
            self._tableView.endUpdates()
            completionHandler(true)
            self.enableOrDisableDone()
        }
        trashAction.backgroundColor = .red
        
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] (action, view, completionHandler) in
            
             let tag = self._tags[indexPath.item]
            
            let controller = UIAlertController(title: "Rename Tag", message: "", preferredStyle: .alert)
            controller.addTextField {
                $0.text = tag.name
            }
           
            let submitAction = UIAlertAction(title: "Ok", style: .default) { [unowned controller] _ in
                let field = controller.textFields![0]
                if let name = field.text, name != String.empty, name != tag.name {
                    tag.name = name
                    self._editedTags[tag.id] = tag
                    
                    self._tableView.beginUpdates()
                    self._tableView.reloadRows(at: [indexPath], with: .fade)
                    self._tableView.endUpdates()
                    self.enableOrDisableDone()
                }
            }
            controller.addAction(submitAction)
            
            controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(controller, animated: true, completion: nil)
            
            completionHandler(true)
            
        }
        editAction.backgroundColor = #colorLiteral(red: 0.9898452163, green: 0.4851491451, blue: 0.2580373287, alpha: 1)
        
        let configuration = UISwipeActionsConfiguration(actions: [trashAction, editAction])
        return configuration
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if let tableSection = TableSection(rawValue: indexPath.section) {
            switch tableSection {
            case .tags:
                let tag = _tags[indexPath.row]
                 return tag.isUser
                
            case .settings:
                return false
            }
        }
        return false
    }
    
    private func enableOrDisableDone() -> Void {
//        if _editedTags.isEmpty == false {
//            let tags: [Int64: TagEntity] = _tags.toDictionary{$0.id}
//            var remove = [TagEntity]()
//            for item in _editedTags.values {
//                if tags[item.id]?.name == item.name {
//                    remove.append(item)
//                }
//            }
//            remove.forEach {
//                _editedTags.removeValue(forKey: $0.id)
//            }
//        }
        
        if _removedTags.isEmpty == false || _editedTags.isEmpty == false {
            _btDone.isEnabled = true
        } else {
            _btDone.isEnabled = false
        }
    }
}

private class SettingsItem {
    let text: String
    
    init(text: String) {
        self.text = text
    }
}

final class TagCell: UITableViewCell {
    
    @IBOutlet weak var _text: UILabel!
    //    @IBOutlet weak var _text: UILabel!
}

