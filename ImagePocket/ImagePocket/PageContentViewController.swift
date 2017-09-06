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
    @IBOutlet weak var _imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Image"

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateContent()
    }
    
    private var targetSize: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: _imageView.bounds.width * scale, height: _imageView.bounds.height * scale)
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
