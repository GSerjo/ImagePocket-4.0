//
//  ImagePageViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 9/4/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit

class ImagePageViewController: UIPageViewController, UIPageViewControllerDataSource {

    private var _images = [ImageEntity]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func setup(entities: [ImageEntity]) -> Void {
        _images = entities
    }
    
}
