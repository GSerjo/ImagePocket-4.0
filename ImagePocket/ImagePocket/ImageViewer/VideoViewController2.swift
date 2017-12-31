//
//  VideoViewController2.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 12/31/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import UIKit
import AVKit

class VideoViewController2: AVPlayerViewController {   
    
    let fetchPlayerItemBlock: FetchPlayerItemBlock
    
    init(index: Int, itemCount: Int, fetchImageBlock: @escaping FetchImageBlock, fetchBlock: @escaping FetchPlayerItemBlock, scrubber: VideoScrubber, configuration: GalleryConfiguration, isInitialController: Bool = false) {
        
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
