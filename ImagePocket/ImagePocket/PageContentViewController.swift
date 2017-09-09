//
//  PageContentViewController.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 9/5/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit
import Photos

final class PageContentViewController: UIViewController {

    var pageIndex = 0
    var imageEntity: ImageEntity?
    
    var notifiableOnTap: NotifiableOnTapProtocol?

    @IBOutlet weak var _imageView: UIImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Image"
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onViewTapped))
        self.view.addGestureRecognizer(tapGesture)
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
        
        updateImage(asset)
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
