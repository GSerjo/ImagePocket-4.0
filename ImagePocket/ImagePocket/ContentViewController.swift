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

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

extension ContentViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        setReadMode()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterImages(by: searchText)
    }
}

class ContentViewController: UIViewController, SideMenuControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NotifiableOnCloseProtocol {
    
    private let _showTagSelectorSegue = "showTagSelector"
    private let _showImagePage = "showImagePage"
    private let _selectImagesTitle = "Select Images"
    private let _rootTitle = "Image Pocket"
    
    @IBOutlet weak var _btTrash: UIBarButtonItem!
    @IBOutlet weak var _btShare: UIBarButtonItem!
    @IBOutlet var _btSearch: UIBarButtonItem!
    @IBOutlet var _btSelect: UIBarButtonItem!
    @IBOutlet var _btCancel: UIBarButtonItem!
    @IBOutlet var _btTag: UIBarButtonItem!
    @IBOutlet weak var _collectionView: UICollectionView!
    
    private var _btOpenMenu: [UIBarButtonItem]!
    private var _imageCache: ImageCache!
    private let _imageManager = PHCachingImageManager()
    private var _filteredImages = [ImageEntity]()
    private var _selectedImages = [String: ImageEntity]()
    private var _viewMode = ViewMode.read
    private var _thumbnailSize: CGSize!
    private var _previousPreheatRect = CGRect.zero
    private var _selectedImageIndex: Int!
    
    private enum ViewMode {
        case read
        case select
        case search
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
        
//        setReadMode()
        updateItemSize()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        updateItemSize()
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
        guard let menuController = sideMenuController.sideViewController as? MenuController else {
            return
        }
        
        filterImages(by: menuController.selectedTag)
    }
    
    func sideMenuControllerDidReveal(_ sideMenuController: SideMenuController) {
        if let menuController = sideMenuController.sideViewController as? MenuController {
            menuController.didReveal()
        }
    }
    
    func notifyOnClose() {
        unselectImages()
        setReadMode()
    }
    
    private func unselectImages() -> Void {
        _selectedImages = [String: ImageEntity]()
        reloadData()
    }
    
    private func startApp(){
        if(PHPhotoLibrary.authorizationStatus() == .authorized){
            startAppCore()
        }
        else{
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    private func filterImages(by tag: TagEntity?) -> Void {
        if let tagEntity = tag {
            _filteredImages = _imageCache.getImages(tag: tagEntity)
            reloadData()
        }
    }
    
    fileprivate func filterImages(by searchText: String) -> Void {
        _filteredImages = _imageCache.getImages(searchText: searchText)
        reloadData()
    }
    
    private func reloadData() {
        _collectionView.reloadData()
    }
    
    private func configureToolbar(){
        navigationItem.rightBarButtonItems = [_btSelect, _btSearch]
        _btOpenMenu = navigationItem.leftBarButtonItems
    }
    
    @IBAction func onTagClicked(_ sender: Any) {
        performSegue(withIdentifier: _showTagSelectorSegue, sender: nil)
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        setReadMode()
        unselectImages()
    }
    
    @IBAction func onSelectClicked(_ sender: Any) {
        setSelectMode()
    }
    
    @IBAction func onSearchClicked(_ sender: Any) {
        setSearchMode()
    }
    
    fileprivate func setReadMode() -> Void {
        _viewMode = .read
        
        navigationItem.titleView = nil
        title = _rootTitle
        _selectedImages = [String: ImageEntity]()
        
        _btShare.isEnabled = false
        _btTrash.isEnabled = false
        
        navigationItem.leftBarButtonItems = _btOpenMenu
        navigationItem.rightBarButtonItems = [_btSelect, _btSearch]
    }
    
    
    private func setSelectMode() -> Void {
        _viewMode = .select
        self.title = _selectImagesTitle
        
        navigationItem.leftBarButtonItems = [_btTag]
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        navigationItem.rightBarButtonItems = [_btCancel]
    }
    
    private func setSearchMode() -> Void {
        _viewMode = .search
        
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        
        let searchBar = UISearchBar()
        searchBar.showsCancelButton = true
        searchBar.delegate = self
        searchBar.placeholder = "Search Photos"
        
        navigationItem.titleView = searchBar
        
        searchBar.becomeFirstResponder()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == _showTagSelectorSegue {
            let controller = segue.destination as! TagSelectorViewController
            controller.setup(entities: _selectedImages.values.toArray(), notifiableOnCloseProtocol: self)
        }
            
        else if segue.identifier == _showImagePage {
            let backItem = UIBarButtonItem()
            navigationItem.backBarButtonItem = backItem
            let controller = segue.destination as! ImagePageViewController
            controller.setup(entities: _filteredImages, selectedImageIndex: _selectedImageIndex)
        }
        
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
    
    // CollectionView
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = _collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImagePreviewCell.self), for: indexPath) as? ImagePreviewCell
            else {
                fatalError("unexpected cell in collection view")
        }
        
        let image = _filteredImages[indexPath.item]
        guard let asset = _imageCache[image.localIdentifier]
            else{
                fatalError("unexpected image")
        }
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        if _selectedImages.keys.contains(cell.representedAssetIdentifier) {
            cell.selectCell()
        }else {
            cell.deselectCell()
        }
        
        _imageManager.requestImage(for: asset, targetSize: _thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier && image != nil {
                cell.thumbnailImage = image
            }
        })
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if _viewMode != .select {
            if _viewMode == .search {
                setReadMode()
            }
            _selectedImageIndex = indexPath.item
            performSegue(withIdentifier: _showImagePage, sender: nil)
            return
        }
        
        let cell = collectionView.cellForItem(at: indexPath) as! ImagePreviewCell
        let image = _filteredImages[indexPath.item]
        
        
        if _selectedImages.keys.contains(image.localIdentifier) {
            
            _selectedImages.removeValue(forKey: image.localIdentifier)
            cell.deselectCell()
        }
        else {
            _selectedImages[image.localIdentifier] = image
            cell.selectCell()
        }
        
        navigationItem.leftBarButtonItem?.isEnabled = _selectedImages.count != 0
    }
    
    
    private func updateItemSize() -> Void {
        
        let viewWidth = view.bounds.size.width
        
        let desiredItemWidth: CGFloat = 100
        let columns: CGFloat = max(floor(viewWidth / desiredItemWidth), 4)
        let padding: CGFloat = 1
        let itemWidth = floor((viewWidth - (columns - 1) * padding) / columns)
        let itemSize = CGSize(width: itemWidth, height: itemWidth)
        
        if let layout = _collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = itemSize
            layout.minimumInteritemSpacing = padding
            layout.minimumLineSpacing = padding
        }
        
        let scale = UIScreen.main.scale
        _thumbnailSize = CGSize(width: itemSize.width * scale, height: itemSize.height * scale)
    }
    
    private func startAppCore(){
        _imageCache = ImageCache.instance
        _filteredImages = _imageCache.getImages(tag: TagEntity.all)
        reloadData()
    }
    

    private func updateCachedAssets() {
        // Update only if the view is visible.
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect.
        let visibleRect = CGRect(origin: _collectionView.contentOffset, size: _collectionView.bounds.size)
        let preheatRect = visibleRect.insetBy(dx: 0, dy: -0.5 * visibleRect.height)
        
        // Update only if the visible area is significantly different from the last preheated area.
        let delta = abs(preheatRect.midY - _previousPreheatRect.midY)
        guard delta > view.bounds.height / 3 else { return }
        
        // Compute the assets to start caching and to stop caching.
        let (addedRects, removedRects) = differencesBetweenRects(_previousPreheatRect, preheatRect)
        let addedAssets = addedRects
            .flatMap { rect in _collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in _filteredImages[indexPath.item] }
            .map {entity in _imageCache[entity.localIdentifier]! }
        
        let removedAssets = removedRects
            .flatMap { rect in _collectionView.indexPathsForElements(in: rect) }
            .map { indexPath in _filteredImages[indexPath.item] }
            .map {entity in _imageCache[entity.localIdentifier]! }
        
        // Update the assets the PHCachingImageManager is caching.
        _imageManager.startCachingImages(for: addedAssets,
                                         targetSize: _thumbnailSize, contentMode: .aspectFill, options: nil)
        _imageManager.stopCachingImages(for: removedAssets,
                                        targetSize: _thumbnailSize, contentMode: .aspectFill, options: nil)
        
        // Store the preheat rect to compare against in the future.
        _previousPreheatRect = preheatRect
    }
    
    private func differencesBetweenRects(_ old: CGRect, _ new: CGRect) -> (added: [CGRect], removed: [CGRect]) {
        if old.intersects(new) {
            var added = [CGRect]()
            if new.maxY > old.maxY {
                added += [CGRect(x: new.origin.x, y: old.maxY,
                                 width: new.width, height: new.maxY - old.maxY)]
            }
            if old.minY > new.minY {
                added += [CGRect(x: new.origin.x, y: new.minY,
                                 width: new.width, height: old.minY - new.minY)]
            }
            var removed = [CGRect]()
            if new.maxY < old.maxY {
                removed += [CGRect(x: new.origin.x, y: new.maxY,
                                   width: new.width, height: old.maxY - new.maxY)]
            }
            if old.minY < new.minY {
                removed += [CGRect(x: new.origin.x, y: old.minY,
                                   width: new.width, height: new.minY - old.minY)]
            }
            return (added, removed)
        } else {
            return ([new], [old])
        }
    }
}
