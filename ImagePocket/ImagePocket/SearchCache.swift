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
    private let _dateFormatter: DateFormatter?
    
    static let instance = SearchCache()
    
    private init() {
//        _searchCacheInitialized = UserDefaults.standard.bool(forKey: SearchCacheInitializedName)
        if _searchCacheInitialized {
            _dateFormatter = nil
        } else {
            _dateFormatter = DateFormatter()
            _dateFormatter?.dateFormat = "yyyy LLLL"
        }
    }
        
    public func search(_ terms: [String]) -> [SearchResultEntity] {
        return _searchRepository.search(terms)
    }
    
    public func fill(assets: [PHAsset]) -> Void {
        if _searchCacheInitialized {
            return
        }
        
        let searchEntities = createSearchEntities(assets)
        _searchRepository.save(entities: searchEntities)
        
        UserDefaults.standard.set(true, forKey: SearchCacheInitializedName)
    }
    
    private func createSearchEntities(_ assets: [PHAsset]) -> [SearchEntity] {
        var result = [SearchEntity]()
        
        DispatchQueue.global().sync {
            for asset in assets {
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
                    })
                }
                if let searchEntity = SearchEntity(items, asset.localIdentifier){
                    result.append(searchEntity)
                }
            }
        }
        return result
    }
}


