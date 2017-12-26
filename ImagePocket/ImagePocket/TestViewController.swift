//
//  TestViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 12/24/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let theme = Settings.instance.theme
        let toolBar = UIToolbar()
        toolBar.contentMode = .scaleToFill
        toolBar.barStyle = .default
        toolBar.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        toolBar.backgroundImage(forToolbarPosition: .any, barMetrics:.default)
        
        var items = [UIBarButtonItem]()
        toolBar.barTintColor = theme.barTintColor
        let share = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: nil)
        share.tintColor = theme.tintColor
        items.append(share)
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: nil)
        trash.tintColor = theme.tintColor
        items.append(trash)
        toolBar.setItems(items, animated: false)
    
        
        view.addSubview(toolBar)
        toolBar.sizeToFit()
        toolBar.layoutIfNeeded()
//        toolBar.autoresizesSubviews = true
        
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        let guide = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            toolBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolBar.bottomAnchor.constraintEqualToSystemSpacingBelow(guide.bottomAnchor, multiplier: 1),
//            guide.bottomAnchor.constraintEqualToSystemSpacingBelow(toolBar.bottomAnchor, multiplier: 1)
//            toolBar.heightAnchor.constraint(equalToConstant: 49)
            ])
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
