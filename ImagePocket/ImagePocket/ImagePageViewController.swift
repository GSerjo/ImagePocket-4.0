//
//  ImagePageViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 9/4/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit

final class ImagePageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, NotifiableOnTapProtocol {

    private var _images = [ImageEntity]()
    private var _selectedImageIndex = 0
    private(set) var isFullScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        
        configureToolBar()
        updateOnFullScreen()
        
        self.dataSource = self
        setViewControllers([getViewControllerAtIndex(_selectedImageIndex)] as [UIViewController], direction: .forward, animated: false, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setup(entities: [ImageEntity], selectedImageIndex: Int) -> Void {
        _images = entities
        _selectedImageIndex = selectedImageIndex
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let pageContent: PageContentViewController = viewController as! PageContentViewController
        var index = pageContent.pageIndex
 
        if index == 0 || index == NSNotFound {
            return nil
        }
        index -= 1;
        return getViewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let pageContent: PageContentViewController = viewController as! PageContentViewController
        
        var index = pageContent.pageIndex
        
        if (index == NSNotFound) {
            return nil;
        }
        
        index += 1
        if (index == _images.count) {
            return nil;
        }
        return getViewControllerAtIndex(index)
    }
    
    func notifyOnTap() -> Void {
        isFullScreen = !isFullScreen
        updateOnFullScreen()
    }
    
    private func updateOnFullScreen() -> Void{
        view.backgroundColor = isFullScreen ? UIColor.black : UIColor.white
    }
    
    func onTagClicked() -> Void {
        
    }
    
    private func configureToolBar() -> Void {
        let btTag = UIBarButtonItem(title: "Tag", style: .plain, target: self, action: #selector(onTagClicked))
        navigationItem.rightBarButtonItem = btTag
    }
    

    private func getViewControllerAtIndex(_ index: Int) -> PageContentViewController {
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "PageContentViewController") as! PageContentViewController
        controller.pageIndex = index
        controller.imageEntity = _images[index]
        controller.notifiableOnTap = self
        return controller
    }
    
}
