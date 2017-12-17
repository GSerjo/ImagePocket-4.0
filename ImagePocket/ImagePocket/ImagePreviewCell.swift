//
//  ImagePreviewCell.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 8/23/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit

class ImagePreviewCell: UICollectionViewCell {
    @IBOutlet weak var _imageView: UIImageView!
    @IBOutlet weak var _overlay: UIImageView!
    @IBOutlet weak var _playVideo: UIImageView!
    
    private static let _selected = #imageLiteral(resourceName: "selected2")
    private static let _playVideo = #imageLiteral(resourceName: "playVideo")
    
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            _imageView.image = thumbnailImage
            _imageView.contentMode = .scaleAspectFill
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImage = nil
        _overlay.image = nil
        _playVideo.image = nil
    }
    
    func markAsVideo() -> Void {
        _playVideo.image = ImagePreviewCell._playVideo
        _playVideo.alpha = 0.7
    }
    
    func selectCell() ->  Void {
        _imageView.alpha = 0.7
        _overlay.isHidden = false
        _overlay.image = ImagePreviewCell._selected
    }
    
    func deselectCell() -> Void {
        _imageView.alpha = 1
        _overlay.isHidden = true
    }
}
