//
//  SearchCache.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/1/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import Photos

final class SearchCache {
    
    private let SearchCacheInitializedName = "SearchCacheInitialized"
    private var _searchCacheInitialized = false
    private let _searchRepository = SearchRepository.instance
    
    static let instance = SearchCache()
    private let _imageManager = PHImageManager.default()
    
    
    private init() {
        _searchCacheInitialized = UserDefaults.standard.bool(forKey: SearchCacheInitializedName)
    }
    
    public func fill(asset: PHAsset) -> Void {
        if _searchCacheInitialized {
            return
        }
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        _imageManager.requestImageData(for: asset, options: options, resultHandler: {(imageData, _, _, _) in
            guard let data = imageData,
                let metadata = self.fetchPhotoMetadata(data: data) else {
                return
            }
            print(metadata)
        });
        
        let entity = SearchEntity(text: "", localIdentifier: asset.localIdentifier)
        _searchRepository.save(entity: entity)
    }
    
    private func fetchPhotoMetadata(data: Data) -> [String: Any]? {
        guard let selectedImageSourceRef = CGImageSourceCreateWithData(data as CFData, nil),
            let imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(selectedImageSourceRef, 0, nil) as? [String: Any] else {
                return nil
        }
        return imagePropertiesDictionary
        
    }
}
