//
//  SearchCache.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/1/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import Photos
import CoreLocation

final class SearchCache {
    
    private let SearchCacheInitializedName = "SearchCacheInitialized"
    private var _searchCacheInitialized = false
    private let _searchRepository = SearchRepository.instance
    private let _geoHashAssetRepository = GeoAssetRepository.instance
    private let _geoHashRepository = GeoHashRepository.instance
    private let _dateFormatter: DateFormatter?
    private var _internalProcessedAssets = 0
    private let _locker = NSLock()
    
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
        
        lock(_locker){
            _internalProcessedAssets = 0
        }
        saveGeoAsset(assets)
//        createSearchEntities(assets)
//        UserDefaults.standard.set(true, forKey: SearchCacheInitializedName)
        
        DispatchQueue.global().sync { [unowned self] in
            self.saveGeoAsset(assets)
            let geoHashes = self._geoHashAssetRepository.getUniqueGeoHashes()
            self._geoHashRepository.save(geoHashes: geoHashes)
        }
        
    }
    
    private func saveGeoAsset(_ assets: [PHAsset]) -> Void {
        let geoAssets = assets.map{GeoAssetEntity($0.localIdentifier, $0.location)}.flatMap{$0}
        _geoHashAssetRepository.save(entities: geoAssets)
    }
    
    private func createSearchEntities(_ assets: [PHAsset]) -> Void{
        var result = [SearchEntity]()
        let totalAssets = assets.count
        
        DispatchQueue.global().sync { [unowned self] in
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
                                    print(country)
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
                            } else {
                                print("Test")
                            }
                        }
                        else {
                            print("Test2")
                        }
                        if let searchEntity = SearchEntity(items, asset.localIdentifier){
                            result.append(searchEntity)
                        }
                        self.trySaveSearchEntities(totalAssets, result)
                    })
                } else {
                    if let searchEntity = SearchEntity(items, asset.localIdentifier){
                        result.append(searchEntity)
                    }
                    trySaveSearchEntities(totalAssets, result)
                }
            }
        }
    }
    
    private func trySaveSearchEntities(_ initialAssets: Int, _ searchEntities: [SearchEntity]) -> Void {
        lock(_locker){
            _internalProcessedAssets = _internalProcessedAssets + 1
            if initialAssets == _internalProcessedAssets {
                _searchRepository.save(entities: searchEntities)
            }
        }
        
    }
}


