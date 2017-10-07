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
    private let _dispatchQueue: DispatchQueue?
    private let _dateFormatter: DateFormatter?
    
    static let instance = SearchCache()
    
    private init() {
        _searchCacheInitialized = UserDefaults.standard.bool(forKey: SearchCacheInitializedName)
        if _searchCacheInitialized {
            _dispatchQueue = nil
            _dateFormatter = nil
        } else {
            _dateFormatter = DateFormatter()
            _dateFormatter?.dateFormat = "yyyy LLLL"
            _dispatchQueue = DispatchQueue(label: "SearchQueue")
        }
    }
        
    public func search(text: String) -> [SearchResultEntity] {
        return _searchRepository.search(text: text)
    }
    
    public func fill(assets: [PHAsset]) -> Void {
        for item in assets {
            fill(asset: item)
        }
        UserDefaults.standard.set(true, forKey: SearchCacheInitializedName)
    }
    
    private func fill(asset: PHAsset) -> Void {
        if _searchCacheInitialized {
            return
        }
        
        
        _dispatchQueue?.async {
            var items = [String]()
            
            if let date = asset.creationDate,
                let item =  self._dateFormatter?.string(from: date) {
                items.append(item)
            }
            
            if let location = asset.location {
                CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemark, error) in
                    if error == nil {
                        if let place = placemark?[0] {
                            if let country = place.country {
                                items.append(country)
                            }
                            if let locality = place.locality {
                                items.append(locality)
                            }
                            if let subLocality = place.subLocality {
                                items.append(subLocality)
                            }
                            if let administrativeArea = place.administrativeArea {
                                items.append(administrativeArea)
                            }
                        }
                    }
                    self.save(items: items, localIdentifier: asset.localIdentifier)
                })
            } else {
                self.save(items: items, localIdentifier: asset.localIdentifier)
            }
        }
    }
    
    private func save(items: [String], localIdentifier: String) -> Void {
        if items.isEmpty {
            return
        }
        let entity = SearchEntity(text: items.joined(separator: " "), localIdentifier: localIdentifier)
        self._searchRepository.save(entity: entity)
    }
}
