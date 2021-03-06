//
//  MainViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 12/2/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit
import Photos

private extension UICollectionView {
    func indexPathsForElements(in rect: CGRect) -> [IndexPath] {
        let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect)!
        return allLayoutAttributes.map { $0.indexPath }
    }
}

struct SegueSelector {
    private init() {
    }
    
    static let showTagSelector = "showTagSelector"
    static let showTags = "showTags"
}


class MainViewController: UICollectionViewController,
                            UICollectionViewDelegateFlowLayout,
                            GalleryItemsDataSource,
                            GalleryItemsDelegate,
                            UISearchBarDelegate,
                            NotifiableOnCloseProtocol,
TagsProtocol {
    
    private var _imageCache: ImageCache!
    private var _selectedTag = TagEntity.all
    private let _settings = Settings.instance
    private var _filteredImages = [ImageEntity]()
    private let _imageManager = PHCachingImageManager()
    private var _viewMode = ViewMode.read
    
    private var _selectedImages = [String: (image: ImageEntity, index: IndexPath)]()
    private var _searchText = String.empty
    private var _pendingSearchRequest: DispatchWorkItem?
    private var _previousPreheatRect = CGRect.zero
    private let _thumbnailContentMode: PHImageContentMode = .aspectFill
    private var _thumbnailSize: CGSize!
    private let _sharedImageLoader = SharedImageLoader()
    private var _cellsPerRow = 3
    private let _minimumInteritemSpacing: CGFloat = 3
    private var _lastAccessedCell: IndexPath?
    private var _isInavalidateView = false
    
    @IBOutlet var _btSelect: UIBarButtonItem!
    @IBOutlet var _btSearch: UIBarButtonItem!
    @IBOutlet var _btCancel: UIBarButtonItem!
    @IBOutlet var _btTag: UIBarButtonItem!
    @IBOutlet weak var _btTrash: UIBarButtonItem!
    @IBOutlet weak var _btShare: UIBarButtonItem!
    @IBOutlet var _btMenu: UIBarButtonItem!
    private var _searchBar = UISearchBar()
    @IBOutlet var _collectionView: UICollectionView!
    
    private var isAnyImagesSelected: Bool {
        return _selectedImages.isEmpty == false
    }
    
    private static var _requestPreviewImageOptions: PHImageRequestOptions = {
        let result = PHImageRequestOptions()
        result.deliveryMode = .highQualityFormat
        result.isNetworkAccessAllowed = true
        return result
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        
        try! DataStore.instance.create()
        startApp()
    }
    
    
    override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if(velocity.y > 0) {
            
            UIView.animate(withDuration: 10, delay: 0, options: UIViewAnimationOptions(), animations: {
                UIApplication.applicationWindow.windowLevel = UIWindowLevelStatusBar + 1
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.setToolbarHidden(true, animated: true)
                self.setNeedsStatusBarAppearanceUpdate()
            }, completion: nil)
            
        } else {
            
            UIView.animate(withDuration: 10, delay: 0, options: UIViewAnimationOptions(), animations: {
                UIApplication.applicationWindow.windowLevel = UIWindowLevelNormal
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.setToolbarHidden(false, animated: true)
                self.setNeedsStatusBarAppearanceUpdate()
            }, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateCachedAssets()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onSearchClicked(_ sender: Any) {
        setSearchMode()
    }
    
    @IBAction func onSelectClicked(_ sender: Any) {
        setSelectMode()
    }
    
    @IBAction func onCancelClicked(_ sender: Any) {
        unselectCells()
    }
    
    @IBAction func onTagClicked(_ sender: Any) {
        performSegue(withIdentifier: SegueSelector.showTagSelector, sender: _selectedImages.values.map{$0.image})
    }
    
    @IBAction func onTrashClicked(_ sender: Any) {
        let indexes = _selectedImages.values.map{$0.index.item}
        removeAssests(localIdentifiers: Array(_selectedImages.keys), indexes: indexes)
    }
    
    private func removeAssests(localIdentifiers: [String], indexes: [Int]) -> Void {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(self._imageCache[localIdentifiers] as NSArray)
        }) { (completed, _) in
            if completed {
                self._imageCache.remove(localIdentifiers: localIdentifiers)
                
                let set = Set(indexes)
                var result = [ImageEntity]()
                
                var i = 0
                for item in self._filteredImages {
                    if set.contains(i) == false {
                        result.append(item)
                    }
                    i += 1
                }
                self._filteredImages = result
                DispatchQueue.main.sync {
                    self.setReadMode()
                    self.reloadData()
                }
            }

        }
    }
    
    @IBAction func onMenuClicked(_ sender: Any) {
        performSegue(withIdentifier: SegueSelector.showTags, sender: nil)
    }
    
    @IBAction func onShareClicked(_ sender: Any) {
        _sharedImageLoader.load(images: _selectedImages.values.map{$0.image}) { [unowned self] (loadedImages) in
            let controller = UIActivityViewController(activityItems: loadedImages, applicationActivities: nil)
//            controller.view.backgroundColor = Settings.instance.theme.barTintColor
            controller.popoverPresentationController?.barButtonItem = (sender as! UIBarButtonItem)
            self.present(controller, animated: true, completion: {
                    self.unselectCells()
                })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == SegueSelector.showTagSelector {
            let navigation = segue.destination as! UINavigationController
            let controller = navigation.viewControllers[0] as! TagSelectorViewController
            let entities = sender as! [ImageEntity]
            controller.setup(entities: entities, notifiableOnCloseProtocol: self)
        }
        else if segue.identifier == SegueSelector.showTags {
            let navigation = segue.destination as! UINavigationController
            let controller = navigation.viewControllers[0] as! TagsViewController
            controller.setup(tags: TagCache.instance.allTags, tagsProtocol: self)
        }
    }
    
    func notifyOnClose() {
        let anyImagesSelected = isAnyImagesSelected
        setReadMode()
        if anyImagesSelected {
            reloadData()
        }
    }
    
    // CollectionView
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _filteredImages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = _collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImagePreviewCell.self), for: indexPath) as! ImagePreviewCell
        
        let image = _filteredImages[indexPath.item]
        guard let asset = _imageCache[image.localIdentifier] else {
            fatalError("unexpected image")
        }
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        if _selectedImages.isEmpty == false && _selectedImages.keys.contains(cell.representedAssetIdentifier) {
            cell.selectCell()
        }
        else {
            cell.deselectCell()
        }
        
        if asset.mediaType == .video {
            cell.markAsVideo()
        }
        
        _imageManager.requestImage(for: asset, targetSize: _thumbnailSize, contentMode: _thumbnailContentMode, options: MainViewController._requestPreviewImageOptions, resultHandler: { image, _ in
            if let image = image, cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let marginsAndInsets = flowLayout.sectionInset.left + flowLayout.sectionInset.right + flowLayout.minimumInteritemSpacing * CGFloat(_cellsPerRow - 1)
        let itemWidth = ((collectionView.bounds.size.width - marginsAndInsets) / CGFloat(_cellsPerRow)).rounded(.down)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isLandscape {
            _cellsPerRow = 6
        }
        else {
            _cellsPerRow = 3
        }
        
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        var contentInset = _collectionView.contentInset;
        contentInset.left = self.view.safeAreaInsets.left;
        contentInset.right = self.view.safeAreaInsets.right;
        _collectionView.contentInset = contentInset;
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if _viewMode == .select {
            let cell = collectionView.cellForItem(at: indexPath) as! ImagePreviewCell
            let image = _filteredImages[indexPath.item]
            
            if _selectedImages.keys.contains(image.localIdentifier) {
                
                _selectedImages.removeValue(forKey: image.localIdentifier)
                cell.deselectCell()
            }
            else {
                _selectedImages[image.localIdentifier] = (image, indexPath)
                cell.selectCell()
            }
            
            onSelectedImageChanged()
            
        } else {
            if _viewMode == .search {
                setReadMode()
            }
            
            let galleryViewController = GalleryViewController(startIndex: indexPath.item, itemsDataSource: self, itemsDelegate: self, configuration: galleryConfiguration())
            galleryViewController.swipedToDismissCompletion = onDismissGalleryViewController
            
            let theme = Settings.instance.theme
            
            let headerView = UIView()
            headerView.backgroundColor = theme.barTintColor
            galleryViewController.headerView = headerView

            
            let toolBar = UIToolbar()
            var items = [UIBarButtonItem]()
            toolBar.barTintColor = theme.barTintColor

            let share = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: #selector(galleryViewController.shareItem))
            share.tintColor = theme.tintColor
            items.append(share)
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: nil, action: #selector(galleryViewController.deleteItem))
            trash.tintColor = theme.tintColor
            items.append(trash)
            toolBar.setItems(items, animated: false)

            galleryViewController.footerView = toolBar
            
            present(galleryViewController, animated: false, completion: nil)
        }
    }
    
    private func onDismissGalleryViewController() -> Void {
        if _isInavalidateView {
           reloadData()
           _isInavalidateView = false
        }
    }
    
    // Switch Mode
    private enum ViewMode {
        case read, select, search
    }
    
    private func setSelectMode() -> Void {
        _viewMode = .select
        title = AppTitle.selectImages
        
        navigationItem.leftBarButtonItem = _btTag
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        navigationItem.rightBarButtonItems?.removeAll()
        navigationItem.rightBarButtonItems?.append(_btCancel)
    }
    
    private func setReadMode() -> Void {
        _viewMode = .read
        navigationItem.titleView = nil
        title = AppTitle.root
        
        _selectedImages = [String: (image: ImageEntity, index: IndexPath)]()
        onSelectedImageChanged()
        
        navigationItem.leftBarButtonItem = _btMenu
        navigationItem.rightBarButtonItems?.removeAll()
        
        if navigationItem.rightBarButtonItems == nil {
            navigationItem.rightBarButtonItems = [_btSelect, _btSearch]
        } else{
            navigationItem.rightBarButtonItems!.append(_btSelect)
            navigationItem.rightBarButtonItems!.append(_btSearch)
        }
    }
    
    private func unselectCells() -> Void {
        let selected = _selectedImages.values.map{$0.index}
        setReadMode()
        if selected.isEmpty == false {
            _collectionView.reloadItems(at: selected)
        }
    }
    
    private func onSelectedImageChanged() -> Void {
        _btTrash.isEnabled = isAnyImagesSelected
        _btShare.isEnabled = isAnyImagesSelected
        _btTag.isEnabled = isAnyImagesSelected
    }
    
    private func setSearchMode() -> Void {
        _viewMode = .search
        
        navigationItem.leftBarButtonItems = nil
        navigationItem.rightBarButtonItems = nil
        
        configureSearchCancelButtonIfPad()
        navigationItem.titleView = _searchBar
        
        _searchBar.sizeToFit()
        _searchBar.endEditing(true)
        _searchBar.becomeFirstResponder()
    }
    
    private func configureSearchCancelButtonIfPad() -> Void {
        if UIDevice.current.userInterfaceIdiom != .pad {
            return
        }
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(onCancelSearch))
        navigationItem.rightBarButtonItem = cancelButton
    }
    
    private func imagePreviewCellSize() -> CGSize {
        let cellWidth = _collectionView.frame.width / 3 - 8
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    private func configure() -> Void {
        configureTheme()
        title = AppTitle.root

        _searchBar.showsCancelButton = true
        _searchBar.delegate = self
        _searchBar.placeholder = "Search Photos"
        _searchBar.returnKeyType = UIReturnKeyType.done
        _searchBar.keyboardAppearance = .dark
        
        if #available(iOS 11.0, *) {
            _searchBar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        }
        
        onSelectedImageChanged()
        
        let dummySize = imagePreviewCellSize().width * UIScreen.main.scale
        _thumbnailSize = CGSize(width: dummySize, height: dummySize)
        
        if let flowLayout = _collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumInteritemSpacing = _minimumInteritemSpacing
            flowLayout.minimumLineSpacing = _minimumInteritemSpacing
            flowLayout.sectionInset = UIEdgeInsets(top: _minimumInteritemSpacing, left: _minimumInteritemSpacing, bottom: _minimumInteritemSpacing, right: _minimumInteritemSpacing)
        }
    }
    
    private func configureTheme() -> Void {
    }
    
    private func reloadDataAsync() {
        DispatchQueue.main.async {
            UIView.transition(with: self._collectionView,
                              duration: 0.50,
                              options: .transitionCrossDissolve,
                              animations: { self._collectionView.reloadData()})
        }
    }
    
    private func reloadData(duration: Double = 0.50) {
        UIView.transition(with: self._collectionView,
                          duration: duration,
                          options: .transitionCrossDissolve,
                          animations: { self._collectionView.reloadData()})
    }
    
    private func startApp(){
        if(PHPhotoLibrary.authorizationStatus() == .authorized){
            startAppCore()
        }
        else{
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    private func startAppCore(){
        _selectedTag = _settings.getTag()
        
        _imageCache = ImageCache.instance
        _imageCache.startAsync(onComplete: {
            self.filterImagesAsync(by: self._selectedTag, onComplete: self.reloadDataAsync)
        })
        resetCachedAssets()
    }
    
    
    private func filterImagesAsync(by tag: TagEntity?, onComplete: @escaping () -> Void = {}) -> Void {
        if let tagEntity = tag {
            _selectedTag = tagEntity
            _imageCache.getImagesAsync(tag: tagEntity, onComplete: { images in
                self._filteredImages = images
                onComplete()
            })
        }
    }
    
    private func filterImagesAndReloadAsync(by tag: TagEntity?) -> Void {
        if let tagEntity = tag {
            filterImagesAsync(by: tagEntity, onComplete: reloadDataAsync)
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
    
    // UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        onCancelSearch()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchImages(by: searchText)
    }
    
    @objc func dismissKeyboard() {
        _searchBar.text = nil
        _searchBar.endEditing(false)
    }
    
    @objc private func onCancelSearch() -> Void {
        _searchBar.text = nil
        setReadMode()
        filterImagesAndReloadAsync(by: _selectedTag)
        _searchText = String.empty
    }
    
    private func searchImages(by searchText: String) -> Void {
        _searchText = searchText
        if searchText.isEmpty() {
            return
        }
        _pendingSearchRequest?.cancel()
        let searchRequest = DispatchWorkItem{ [unowned self] in
            self._filteredImages = self._imageCache.search(text: self._searchText)
            DispatchQueue.main.sync {
                self.reloadData()
            }
        }
        _pendingSearchRequest = searchRequest
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(200), execute: searchRequest)
    }
    
    
    // Gallery
    func itemCount() -> Int {
        return _filteredImages.count
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        let image = _filteredImages[index]
        let asset = _imageCache[image.localIdentifier]!
        
        if asset.playbackStyle == .video {
            
            return GalleryItem.video1(fetchPreviewImageBlock: { onComplete in
                ImageLoader.load(asset: asset) { image in onComplete(image) }},
                                      fetchBlock: { onComplete in
                                        ImageLoader.load(asset: asset) { playerItem in onComplete(playerItem) }} )
        }
        
        return GalleryItem.image { onComplete in
            ImageLoader.load(asset: asset) { image in
                onComplete(image)
            }
        }
    }
    
    func provideImageEntity(at index: Int) -> ImageEntity {
        return _filteredImages[index]
    }
    
    func removeGalleryItem(at index: Int, onRemoved: @escaping () -> Void) {
        removeAssest(at: index, onRemoved: onRemoved)
    }
    
    private func removeAssest(at index: Int, onRemoved: @escaping () -> Void) -> Void {
        let ids = [_filteredImages[index].localIdentifier]
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(self._imageCache[ids] as NSArray)
        }) { (completed, _) in
            if completed {
                self._isInavalidateView = true
                self._imageCache.remove(localIdentifiers: ids)
                self._filteredImages.remove(at: index)
                DispatchQueue.main.sync {
                    onRemoved()
                }
            }
        }
    }
    
    //Tags
    func onSelectTag(tag: TagEntity) -> Void {
        filterImagesAndReloadAsync(by: tag)
        _searchText = String.empty
        _searchBar.text = nil
    }
    
    func galleryConfiguration() -> GalleryConfiguration {
        return [
            
            GalleryConfigurationItem.closeButtonMode(.none),
            GalleryConfigurationItem.deleteButtonMode(.none),
            
            GalleryConfigurationItem.thumbnailsButtonMode(.none),
            GalleryConfigurationItem.seeAllCloseButtonMode(.none),
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.displacement),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(false),
            
            GalleryConfigurationItem.swipeToDismissMode(.vertical),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(true),
            GalleryConfigurationItem.activityViewByLongPress(false),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(1),
            GalleryConfigurationItem.overlayBlurOpacity(1),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.light),
            
            GalleryConfigurationItem.videoControlsColor(.white),
            
            GalleryConfigurationItem.maximumZoomScale(10),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(100),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.30),
            
            GalleryConfigurationItem.blurPresentDuration(0.5),
            GalleryConfigurationItem.blurPresentDelay(0),
            GalleryConfigurationItem.colorPresentDuration(0.25),
            GalleryConfigurationItem.colorPresentDelay(0),
            
            GalleryConfigurationItem.blurDismissDuration(0.1),
            GalleryConfigurationItem.blurDismissDelay(0.4),
            GalleryConfigurationItem.colorDismissDuration(0.45),
            GalleryConfigurationItem.colorDismissDelay(0),
            
            GalleryConfigurationItem.itemFadeDuration(0.3),
            GalleryConfigurationItem.decorationViewsFadeDuration(0.4),
            GalleryConfigurationItem.rotationDuration(0.15),
            
            GalleryConfigurationItem.displacementDuration(0.55),
            GalleryConfigurationItem.reverseDisplacementDuration(0.25),
            GalleryConfigurationItem.displacementTransitionStyle(.springBounce(0.7)),
            GalleryConfigurationItem.displacementTimingCurve(.linear),
            
            GalleryConfigurationItem.statusBarHidden(true),
            GalleryConfigurationItem.displacementKeepOriginalInPlace(false),
            GalleryConfigurationItem.displacementInsetMargin(50)
        ]
    }
    
    private func resetCachedAssets() {
        _imageManager.stopCachingImagesForAllAssets()
        _previousPreheatRect = .zero
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
                                         targetSize: _thumbnailSize, contentMode: _thumbnailContentMode, options: nil)
        _imageManager.stopCachingImages(for: removedAssets,
                                        targetSize: _thumbnailSize, contentMode: _thumbnailContentMode, options: nil)
        
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
