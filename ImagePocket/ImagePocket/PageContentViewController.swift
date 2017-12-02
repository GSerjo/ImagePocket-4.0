//
//  PageContentViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 9/5/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit
import Photos

final class PageContentViewController: UIViewController, UIScrollViewDelegate {

    var pageIndex = 0
    var imageEntity: ImageEntity?
    var notifiableOnTap: NotifiableOnTapProtocol?

    @IBOutlet weak var _scrollView: UIScrollView!
    
    var _imageView = UIImageView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _scrollView.delegate = self
//        _scrollView.contentInsetAdjustmentBehavior = .never

        _imageView.frame = CGRect(x: 0, y: 0, width: _scrollView.frame.size.width, height: _scrollView.frame.size.height)
       _imageView.isUserInteractionEnabled = true
       _imageView.contentMode = .scaleAspectFit
       _scrollView.addSubview(_imageView)
    
        setupGestureRecognizer()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setZoomScale()
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let imageViewSize = _imageView.frame.size
        let scrollViewSize = _scrollView.bounds.size
        
        let verticalPadding = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalPadding = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        
        _scrollView.contentInset = UIEdgeInsets(top: verticalPadding, left: horizontalPadding, bottom: verticalPadding, right: horizontalPadding)
    }
    
    private func setupGestureRecognizer() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        _scrollView.addGestureRecognizer(doubleTap)
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
//        self.view.addGestureRecognizer(tapGesture)
        
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(onSwipeDown))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
    }
    
    @objc func onSwipeDown() -> Void {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func onDoubleTap(recognizer: UITapGestureRecognizer) -> Void {
        if (_scrollView.zoomScale > _scrollView.minimumZoomScale) {
            _scrollView.setZoomScale(_scrollView.minimumZoomScale, animated: true)
        } else {
            _scrollView.setZoomScale(_scrollView.maximumZoomScale, animated: true)
        }
    }
    
    private func setZoomScale() {
        let scrollViewFrame = _scrollView.frame
        
        let widthScale = scrollViewFrame.size.width / _scrollView.contentSize.width
        let heightScale = scrollViewFrame.size.height / _scrollView.contentSize.height
        let minScale = min(widthScale, heightScale)
        
        _scrollView.minimumZoomScale = minScale
        _scrollView.maximumZoomScale = 1
        _scrollView.zoomScale = minScale
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return _imageView
    }

    func onViewTapped() -> Void {
        notifiableOnTap?.notifyOnTap()
        updateOnFullScreen()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateOnFullScreen()
        updateContent()
        
        setZoomScale()
    }
    
    private func updateOnFullScreen() -> Void{
        guard let isFullScreen = notifiableOnTap?.isFullScreen else {
            return
        }
        navigationController?.setNavigationBarHidden(isFullScreen, animated: false)
        view.backgroundColor = isFullScreen ? UIColor.black : UIColor.white
    }
    
    private var targetSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: _imageView.bounds.width * scale,
                      height: _imageView.bounds.height * scale)
    }
    
    private func updateContent() -> Void {
        guard let image = imageEntity,
        let asset = ImageCache.instance[image.localIdentifier] else {
            return
        }
        switch asset.playbackStyle {
        case .image:
            updateImage(asset)
        default:
            updateImage(asset)
        }
    }
    
    private func updateImage(_ asset: PHAsset) -> Void {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .fast
        
        PHImageManager.default().requestImage(for: asset,
                                                targetSize: targetSize,
                                                contentMode: .aspectFit,
                                                options: options,
                                                resultHandler: {image, _ in
                
            guard let image = image else {
                return
            }
            self._imageView.image = image
            self._imageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            self._scrollView.contentSize = image.size
//            self.setZoomScale()
        })
    }
}
