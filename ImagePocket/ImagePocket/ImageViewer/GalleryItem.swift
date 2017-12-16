//
//  GalleryItem.swift
//  ImageViewer
//
//  Created by Kristian Angyal on 01/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit
import Photos

public typealias ImageCompletion = (UIImage?) -> Void
public typealias FetchImageBlock = (@escaping ImageCompletion) -> Void

public typealias PlayerItemCompletion = (AVPlayerItem?) -> Void
public typealias FetchPlayerItemBlock = (@escaping PlayerItemCompletion) -> Void
public typealias ItemViewControllerBlock = (_ index: Int, _ itemCount: Int, _ fetchImageBlock: FetchImageBlock, _ configuration: GalleryConfiguration, _ isInitialController: Bool) -> UIViewController

public enum GalleryItem {
    case image(fetchImageBlock: FetchImageBlock)
    case video(fetchPreviewImageBlock: FetchImageBlock, playerItem: AVPlayerItem?)
    case video1(fetchPreviewImageBlock: FetchImageBlock, fetchBlock: FetchPlayerItemBlock)
    case custom(fetchImageBlock: FetchImageBlock, itemViewControllerBlock: ItemViewControllerBlock)
}
