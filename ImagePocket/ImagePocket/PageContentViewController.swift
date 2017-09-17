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
    var _scrollView: UIScrollView!
    
    @IBOutlet weak var _imageView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Image"
        
        _scrollView = UIScrollView(frame: view.bounds)
        _scrollView.contentSize = _imageView.bounds.size
        _scrollView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        _scrollView.delegate = self
        _scrollView.addSubview(_imageView)
        self.view.addSubview(_scrollView)
        
        setZoomScale()
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
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        _scrollView.addGestureRecognizer(doubleTap)
        
//        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
//        self.view.addGestureRecognizer(tapGesture)
    }
    
    func handleDoubleTap(recognizer: UITapGestureRecognizer) {
        if (_scrollView.zoomScale > _scrollView.minimumZoomScale) {
            _scrollView.setZoomScale(_scrollView.minimumZoomScale, animated: true)
        } else {
            _scrollView.setZoomScale(_scrollView.maximumZoomScale, animated: true)
        }
    }
    
    private func setZoomScale() {
        let imageViewSize = _imageView.bounds.size
        let scrollViewSize = _scrollView.bounds.size
        let widthScale = scrollViewSize.width / imageViewSize.width
        let heightScale = scrollViewSize.height / imageViewSize.height
        
        _scrollView.minimumZoomScale = min(widthScale, heightScale)
        _scrollView.zoomScale = 1.0
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
        let asset = ImageCache.inctace[image.localIdentifier] else {
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
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(for: asset,
                                                targetSize: targetSize,
                                                contentMode: .aspectFit,
                                                options: options,
                                                resultHandler: {image, _ in
                
            guard let image = image else {
                return
            }
            self._imageView.image = image
        })
    }
}
