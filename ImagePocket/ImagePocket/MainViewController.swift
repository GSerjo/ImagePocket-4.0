//
//  MainViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 12/2/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit
import Photos

class MainViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, GalleryItemsDataSource {

    private var _imageCache: ImageCache!
    private var _selectedTag = TagEntity.all
    private let _settings = Settings.instance
    private var _filteredImages = [ImageEntity]()
    private let _imageManager = PHCachingImageManager()
    
    private lazy var _requestPreviewImageOptions: PHImageRequestOptions = {
        let result = PHImageRequestOptions()
        result.deliveryMode = .highQualityFormat
        result.isNetworkAccessAllowed = true
        return result
    }()
    
    
    @IBOutlet var _collectionView: UICollectionView!
    
    override func viewDidLoad() {
        configure()
        startApp()
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
        _imageManager.requestImage(for: asset, targetSize: imagePreviewCellSize(), contentMode: .aspectFill, options: _requestPreviewImageOptions, resultHandler: { image, _ in
            if let image = image, cell.representedAssetIdentifier == asset.localIdentifier {
                cell.thumbnailImage = image
            }
        })
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return imagePreviewCellSize()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath) as! ImagePreviewCell
//        let image = _filteredImages[indexPath.item]
//        let photos = _imageCache[_filteredImages.map{$0.localIdentifier}].map{SKPhoto(asset: $0)}
        
        let galleryViewController = GalleryViewController(startIndex: indexPath.item, itemsDataSource: self, configuration: galleryConfiguration())
        
        present(galleryViewController, animated: false, completion: nil)
    }
    
    public func loadUnderlyingImageAndNotify(_asset: PHAsset) -> Void {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(for: _asset,
                                              targetSize: CGSize(width: _asset.pixelWidth, height: _asset.pixelHeight),
                                              contentMode: .aspectFit,
                                              options: options,
                                              resultHandler: { image, info in
                                                if let image = image {
                                                    print(image)
                                                }
                                                else {
                                                    print(info!)
                                                }
                                                
        })
    }
    
    // Gallery
    func itemCount() -> Int {
        return _filteredImages.count
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        let image = _filteredImages[index]
        
        let result = GalleryItem.image { onComplete in
            ImageLoader.load(asset: self._imageCache[image.localIdentifier]!) { image in
                onComplete(image)
            }
        }
        return result
    }
    
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.closeButtonMode(.builtIn),
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.displacement),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(false),
            
            GalleryConfigurationItem.swipeToDismissMode(.vertical),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(false),
            GalleryConfigurationItem.activityViewByLongPress(false),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(1),
            GalleryConfigurationItem.overlayBlurOpacity(1),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.light),
            
            GalleryConfigurationItem.videoControlsColor(.white),
            
            GalleryConfigurationItem.maximumZoomScale(8),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(100),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.15),
            
            GalleryConfigurationItem.blurPresentDuration(0.5),
            GalleryConfigurationItem.blurPresentDelay(0),
            GalleryConfigurationItem.colorPresentDuration(0.25),
            GalleryConfigurationItem.colorPresentDelay(0),
            
            GalleryConfigurationItem.blurDismissDuration(0.1),
            GalleryConfigurationItem.blurDismissDelay(0.4),
            GalleryConfigurationItem.colorDismissDuration(0.45),
            GalleryConfigurationItem.colorDismissDelay(0),
            
            GalleryConfigurationItem.itemFadeDuration(0.3),
            GalleryConfigurationItem.decorationViewsFadeDuration(0.15),
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
    
    
    private func imagePreviewCellSize() -> CGSize {
        let cellWidth = _collectionView.frame.width / 3 - 8
        return CGSize(width: cellWidth, height: cellWidth)
    }
    
    private func configure() -> Void {
        title = AppTitle.root
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
    
    private func reloadDataAsync() {
        DispatchQueue.main.async { [unowned self] in
            self.reloadData()
        }
    }
    
    private func reloadData() {
        _collectionView.reloadData()
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
}
