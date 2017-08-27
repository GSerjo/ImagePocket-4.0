//
//  TagSelectorViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 8/27/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit

class TagSelectorViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onDoneClicked(_ sender: Any) {
    }
    
}
