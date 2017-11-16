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
    private let _minute: TimeInterval = 60.0
    private let _loadAddressInterval: TimeInterval
    private var _loadAddressTimer: Timer?
    
    static let instance = SearchCache()
    
    private init() {
//        _loadAddressInterval = 2 * _minute
        _loadAddressInterval = 10
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
//        saveGeoAsset(assets)÷
//        createSearchEntities(assets)
//        UserDefaults.standard.set(true, forKey: SearchCacheInitializedName)
        
        DispatchQueue.global().sync { [unowned self] in
            self.saveGeoAsset(assets)
            let geoHashes = self._geoHashAssetRepository.getUniqueGeoHashes()
            self._geoHashRepository.save(entities: geoHashes.map{$0.toGeoHash()})
            enqueueLoadAddressWorkItem(delayInSeconds: 5)
        }
    }
    
    private func saveGeoAsset(_ assets: [PHAsset]) -> Void {
        let geoAssets = assets.map{GeoAssetEntity($0.localIdentifier, $0.location)}.flatMap{$0}
        _geoHashAssetRepository.save(entities: geoAssets)
    }
    
    private func enqueueLoadAddressWorkItem(delayInSeconds: Int) -> Void {
        let workItem = DispatchWorkItem{ [unowned self] in
            self.loadAddress()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(delayInSeconds), execute: workItem)
    }
    
    private func loadAddress() -> Void {
        let items = _geoHashRepository.getUnprocessedChunk()
        if items.isEmpty {
            _loadAddressTimer?.invalidate()
            _loadAddressTimer = nil
            return
        }

        enqueueLoadAddressWorkItem(delayInSeconds: 180)
        
        for item in items {
            guard let coordinate = Geohash.decode(item.geoHash) else {
                continue
            }
            var addressItems = [String]()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemark, error) in
                if error == nil {
                    if let place = placemark?[0] {
                        if let country = place.country {
                            addressItems.append(country)
                        }
                        if let locality = place.locality {
                            addressItems.append(locality)
                        }
                        if let subLocality = place.subLocality {
                            addressItems.append(subLocality)
                        }
                        if let administrativeArea = place.administrativeArea {
                            addressItems.append(administrativeArea)
                        }
                    }
                    item.setAddress(addressItems)
                    self._geoHashRepository.updateProcessed(entity: item)
                }
            })
        }
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


