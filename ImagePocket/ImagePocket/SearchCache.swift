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
    private let _searchRepository = SearchRepository.instance
    private let _geoHashAssetRepository = GeoAssetRepository.instance
    private let _geoHashRepository = GeoHashRepository.instance
    private let _dateFormatter = DateFormatter()
    
    static let instance = SearchCache()
    
    private init() {
        _dateFormatter.dateFormat = "yyyy LLLL"
    }
    
    public func search(_ terms: [String]) -> [SearchResultEntity] {
        return _searchRepository.search(terms)
    }
    
    public func fill(assets: [PHAsset]) -> Void {
        DispatchQueue.global().sync { [unowned self] in
            self.saveGeoAsset(assets)
            let geoHashes = self._geoHashAssetRepository.getUniqueGeoHashes()
            self._geoHashRepository.save(entities: geoHashes.map{$0.toGeoHash()})
            self.enqueueLoadAddressWorkItem()
        }
    }
    
    public func enqueueLoadAddressWorkItem(delayInSeconds: Int = 5) -> Void {
        let workItem = DispatchWorkItem{ [unowned self] in
            self.loadAddress()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(delayInSeconds), execute: workItem)
    }
    
    private func saveGeoAsset(_ assets: [PHAsset]) -> Void {
        let geoAssets = assets.map{GeoAssetEntity($0.localIdentifier, $0.location)}.flatMap{$0}
        _geoHashAssetRepository.save(entities: geoAssets)
    }
    
    private func loadAddress() -> Void {
        let items = _geoHashRepository.getUnprocessedChunk()
        if items.isEmpty {
            return
        }

        enqueueLoadAddressWorkItem(delayInSeconds: 180)
        
        for item in items {
            var addressItems = [String]()
            let location = CLLocation(latitude: item.latitude, longitude: item.longitude)
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
}


