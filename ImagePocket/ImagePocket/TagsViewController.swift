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
    private var _deletedTags = [TagEntity]()
    
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

            self._deletedTags.append(self._tags[indexPath.item])
            self._tags.remove(at: indexPath.item)

            self._tableView.beginUpdates()
            self._tableView.deleteRows(at: [indexPath], with: .automatic)
            self._tableView.endUpdates()
            completionHandler(true)
        }
        trashAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [trashAction])
        return configuration
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
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

