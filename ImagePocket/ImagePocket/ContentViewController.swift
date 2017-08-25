//
//  ContentViewController.swift
//  ImagePocket
//
//  Created by Serjo on 23/10/16.
//  Copyright © 2016 Serjo. All rights reserved.
//

import UIKit
import Photos
import SideMenuController

class ContentViewController: UIViewController, SideMenuControllerDelegate, UICollectionViewDataSource {

    private let _selectImagesTitle = "Select Images"
    private let _rootTitle = "Image Pocket"
    private let _tagButtonName = "Tag"
    private let _cancelButtonName = "Cancel"
    private let _selectButtonName = "Select"
    
    @IBOutlet weak var _btTrash: UIBarButtonItem!
    @IBOutlet weak var _btShare: UIBarButtonItem!
    private var _btTag: UIBarButtonItem!
    private var _btCancel: UIBarButtonItem!
    private var _btOpenMenu: UIBarButtonItem!
    private var _btSelect: UIBarButtonItem!
    
    private var _imageCache: ImageCache!
    private let _imageManager = PHCachingImageManager()
    private var _filteredImages = [ImageEntity]()
    private var _selectedImages = [String: ImageEntity]()
    private var _viewMode = ViewMode.read
    @IBOutlet weak var _collectionView: UICollectionView!
    
    private enum ViewMode {
        case read
        case select
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barTintColor = randomColor
        sideMenuController?.delegate = self
        
        self.title = _rootTitle
        configureToolbar()
        setReadMode()
        
        startApp()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func presentAction() {
        //present(ViewController.fromStoryboard, animated: true, completion: nil)
    }
    
    var randomColor: UIColor {
        let colors = [UIColor(hue:0.65, saturation:0.33, brightness:0.82, alpha:1.00),
                      UIColor(hue:0.57, saturation:0.04, brightness:0.89, alpha:1.00),
                      UIColor(hue:0.55, saturation:0.35, brightness:1.00, alpha:1.00),
                      UIColor(hue:0.38, saturation:0.09, brightness:0.84, alpha:1.00)]
        
        let index = Int(arc4random_uniform(UInt32(colors.count)))
        return colors[index]
    }
    
    func sideMenuControllerDidHide(_ sideMenuController: SideMenuController) {
    }
    
    func sideMenuControllerDidReveal(_ sideMenuController: SideMenuController) {
    }
    
    private func configureToolBar(){
        
    }
    
    private func startApp(){
        if(PHPhotoLibrary.authorizationStatus() == .authorized){
            startAppCore()
        }
        else{
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    private func configureToolbar(){
        _btTag = UIBarButtonItem(title: _tagButtonName, style: .plain, target: self, action: #selector(onTagClicked))
        _btCancel = UIBarButtonItem(title: _cancelButtonName, style: .plain, target: self, action: #selector(onCancelClicked))
        _btSelect = UIBarButtonItem(title: _selectButtonName, style: .plain, target: self, action: #selector(onSelectClicked))
        navigationItem.rightBarButtonItems = [_btSelect]
        _btOpenMenu = navigationItem.leftBarButtonItem
    }
    
    func onTagClicked() {
        
    }
    
    func onCancelClicked() {
        setReadMode()
    }
    
    func onSelectClicked() {
        setSelectMode()
    }
    
    private func requestAuthorizationHandler(_ status: PHAuthorizationStatus){
        DispatchQueue.main.sync {
            if(status == .authorized){
                startAppCore()
            }
            else {
                
                let alertController = UIAlertController(title: "Warning", message: "The Photo permission was not authorized. Please enable it in Settings to continue", preferredStyle: .alert)
                let settingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: {_ in
                    if let appSettings = URL(string: UIApplicationOpenSettingsURLString){
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    }
                })
                
                alertController.addAction(settingsAction)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                alertController.addAction(cancelAction)
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _filteredImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = _collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePreviewCell", for: indexPath) as! ImagePreviewCell
        return cell
    }
    
    private func startAppCore(){
        _imageCache = ImageCache.inctace
    }
    
    private func setReadMode() {
        _viewMode = .read
        
        self.title = _rootTitle
        _selectedImages = [String: ImageEntity]()
        
        _btShare.isEnabled = false
        _btTrash.isEnabled = false
        
        //navigationItem.leftBarButtonItems = [_btOpenMenu]
        navigationItem.rightBarButtonItem = _btSelect
    }

    
    private func setSelectMode() {
        _viewMode = .select
        self.title = _selectImagesTitle
        
        navigationItem.rightBarButtonItem = _btCancel
        navigationItem.leftBarButtonItem = _btTag
        navigationItem.leftBarButtonItem?.isEnabled = false
    }
}
