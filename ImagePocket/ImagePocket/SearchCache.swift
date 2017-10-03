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
    private let _searchRepository: SearchRepository?
    private let _dispatchQueue: DispatchQueue?
    private let _dateFormatter: DateFormatter?
    
    static let instance = SearchCache()
    
    private init() {
        _searchCacheInitialized = UserDefaults.standard.bool(forKey: SearchCacheInitializedName)
        if _searchCacheInitialized {
            _dispatchQueue = nil
            _searchRepository = nil
            _dateFormatter = nil
        } else {
            _dateFormatter = DateFormatter()
            _dateFormatter?.dateFormat = "yyyy LLLL"
            _searchRepository = SearchRepository.instance
            _dispatchQueue = DispatchQueue(label: "SearchQueue")
        }
    }
    
    public func fill(asset: PHAsset) -> Void {
        if _searchCacheInitialized {
            return
        }
        
        
        _dispatchQueue?.async {
            var items = [String]()
            
            if let date = asset.creationDate,
                let item =  self._dateFormatter?.string(from: date) {
                items.append(item)
            }
            
//            let t = asset.location
            
            let entity = SearchEntity(text: items.joined(separator: " "), localIdentifier: asset.localIdentifier)
            self._searchRepository?.save(entity: entity)
        }
    }
    
    private func fetchPhotoMetadata(data: Data) -> [String: Any]? {
        guard let selectedImageSourceRef = CGImageSourceCreateWithData(data as CFData, nil),
            let imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(selectedImageSourceRef, 0, nil) as? [String: Any] else {
                return nil
        }
        return imagePropertiesDictionary
    }
}
