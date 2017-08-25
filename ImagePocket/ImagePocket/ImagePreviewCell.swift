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
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            _image.image = thumbnailImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImage = nil
    }
}
