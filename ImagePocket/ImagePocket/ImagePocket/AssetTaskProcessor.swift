//
//  AssetTaskProcessor.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/19/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import Photos

final class AssetTaskProcessor {
    private let _assetTaskRepositoty = AssetTaskResitory.instance
    private let _searchRepository = SearchRepository.instance
    private let _geoHashRepository = GeoHashRepository.instance
    private let _settings = Settings.instance
    
    public static let instance = AssetTaskProcessor()
    
    private init(){
    }
    
    public func enqueueTask() -> Void {
        enqueueForGeoSearchItem()
        enqueueForReadyWorkItem()
    }
    
    public func enqueueTasks(tasks: [AssetTaskable]) -> Void {
        
        if _settings.appStatus != .none && _settings.appStatus != .assetTaskProcessed {
            if _assetTaskRepositoty.isEmpty() {
                _settings.appStatus = .assetTaskProcessed
            }
        }
        
        switch _settings.appStatus {
            case .none:
                addAssetTasks(tasks: tasks)
                enqueueForGeoSearchItem()
            case .assetTaskLoaded:
                enqueueTask()
            case .assetTaskProcessed:
                updateAssetTasks(tasks: tasks)
                enqueueTask()
        }
    }
    
    private func addAssetTasks(tasks: [AssetTaskable]) -> Void {
        let assetTasks = tasks.map{AssetTaskEntity(task: $0)}.flatMap{$0}
        _assetTaskRepositoty.save(assetTasks)
        _settings.appStatus = .assetTaskLoaded
    }
    
    private func updateAssetTasks(tasks: [AssetTaskable]) -> Void {
        AssetRespository.instance.update(tasks: tasks)
    }
    
    private func enqueueForReadyWorkItem(delayInSeconds: Int = 5) -> Void {
        let workItem = DispatchWorkItem { [unowned self] in
            self.processForReadyTasks()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(delayInSeconds), execute: workItem)
    }
    
    private func processForReadyTasks() -> Void {
        let entities = _assetTaskRepositoty.getForReady()
        if entities.isEmpty {
            return
        }
        _assetTaskRepositoty.markAsReady(entities)
        _assetTaskRepositoty.removeReady()
    }
    
    private func enqueueForGeoSearchItem(delayInSeconds: Int = 5) -> Void {
        let workItem = DispatchWorkItem{ [unowned self] in
            self.processForGeoSearchTasks()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(delayInSeconds), execute: workItem)
    }
    
    private func processForGeoSearchTasks() -> Void {
        let entities = _assetTaskRepositoty.getForGeoSearchChunk()
        if entities.isEmpty {
            return
        }
        
        enqueueForReadyWorkItem(delayInSeconds: 60)
        enqueueForGeoSearchItem(delayInSeconds: 80)
        
        var notProcessed = [AssetTaskEntity]()
        
        for entity in entities {
            
            if let geoHash = self._geoHashRepository.get(geoHash: entity.geoHash!) {
                
                entity.setAddress(address: geoHash.address)
                self._assetTaskRepositoty.markAsForReady(entity)
                
            } else {
                notProcessed.append(entity)
            }
        }
        
        notProcessed = notProcessed.distinct()
        
        for entity in notProcessed {
            var items = [String]()
            let location = CLLocation(latitude: entity.latitude!, longitude: entity.longitude!)
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
                    entity.setAddress(items)
                    self._assetTaskRepositoty.updateAddress(entity)
                }
            })
        }
    }
}
