//
//  ImagePreviewCell.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 8/23/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit

class ImagePreviewCell: UICollectionViewCell {
    
    @IBOutlet weak var _image: UIImageView!
    @IBOutlet weak var _overlay: UIImageView!
    
    private static let _selected = #imageLiteral(resourceName: "selected")
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            _image.image = thumbnailImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImage = nil
        _overlay.image = nil
    }
    
    func selectCell() {
        _image.alpha = 0.6
        _overlay.isHidden = false
        _overlay.image = ImagePreviewCell._selected

    }
    
    func deselectCell(){
        _image.alpha = 1
        _overlay.isHidden = true
    }
}
