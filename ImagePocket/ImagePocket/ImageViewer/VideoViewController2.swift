//
//  VideoViewController2.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 12/31/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit
import AVKit

class VideoViewController2: AVPlayerViewController, ItemController {
    var index: Int
    
    var isInitialController: Bool
    
    var controllerDelegate: ItemControllerDelegate?
    
    var displacedViewsDataSource: GalleryDisplacedViewsDataSource?
    
    func fetchImage() {
    }
    
    func presentItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void) {
    }
    
    func dismissItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void) {
    }
    
    func closeDecorationViews(_ duration: TimeInterval) {
    }
    
    
    let fetchPlayerItemBlock: FetchPlayerItemBlock
    
    init(index: Int, itemCount: Int, fetchImageBlock: @escaping FetchImageBlock, fetchBlock: @escaping FetchPlayerItemBlock, scrubber: VideoScrubber, configuration: GalleryConfiguration, isInitialController: Bool = false) {
        
        self.index = index
        self.isInitialController = isInitialController
        
        fetchPlayerItemBlock = fetchBlock
        
        super.init(nibName: nil, bundle: nil)
        player = AVPlayer(playerItem: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchPlayerItem()
    }
    
    private func fetchPlayerItem() {
        fetchPlayerItemBlock { playerItem in
            if let playerItem = playerItem {
                DispatchQueue.main.async {
                    self.player?.replaceCurrentItem(with: playerItem)
                }
            }
        }
    }
}
