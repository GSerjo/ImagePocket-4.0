//
//  ImageCache.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 8/20/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import Photos

extension PHAsset: AssetTaskable {
    var latitude: Double? {
        return self.location?.coordinate.latitude
    }
    
    var longitude: Double? {
        return self.location?.coordinate.longitude
    }
}

final class ImageCache{
    
    static let instance = ImageCache()
    private let _imageRepository = ImageRepository.instance
    private var _taggedImages = [String: ImageEntity]()
    private var _actualImages = [String:ImageEntity]()
    private let _tagCache = TagCache.instance
    private let _searchCache = SearchCache.instance
    var fetchResult: PHFetchResult<PHAsset>!
    
    subscript(localId: String) -> PHAsset?{
//        print("requested: \(localId)")
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localId], options: nil)
        return result.firstObject
    }
    
    func start(onComplete: @escaping () -> Void) -> Void {
        DispatchQueue.global().async {[unowned self] in
            self._taggedImages = self._imageRepository.getAll().toDictionary{$0.localIdentifier}
            
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            self.fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
            
            let assets = self.getAssets(self.fetchResult)
            AssetTaskProcessor.instance.initTasks(tasks: assets)
        
            self._actualImages  = assets.map(self.createImage).toDictionary{$0.localIdentifier}
            
            self.syncImages()
            
            onComplete()
//            print(self._actualImages)
        }
    }
    
    public func changeDetails(changeInstance: PHChange) -> PHFetchResultChangeDetails<PHAsset>? {
        return changeInstance.changeDetails(for: fetchResult)
    }
    
    public func photoLibraryDidChange(changes: PHFetchResultChangeDetails<PHAsset>, changeInstance: PHChange) -> Void {
        if changes.hasIncrementalChanges == false {
            return
        }
        
        fetchResult = changes.fetchResultAfterChanges
        remove(localIdentifiers: changes.removedObjects.map{$0.localIdentifier})
        addAssets(assets: changes.insertedObjects)
    }
    
   public func search(text: String) -> [ImageEntity] {
        if text.isEmpty() {
            return getImages(tag: TagEntity.all)
        }
        
        let terms = text.components(separatedBy: " ").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty()}
        
        var result = [ImageEntity]()
        for item in _taggedImages.values {
            
            for searchText in terms {
                if item.hasSearchableText(text: searchText){
                    result.append(item)
                    break
                }
            }
        }

        let searchResult = _searchCache.search(terms)
        result.append(contentsOf: searchResult.flatMap{_actualImages[$0.localIdentifier]})
        
        result = result.distinct()
        result.sort{$0.creationDate ?? Date() > $1.creationDate ?? Date()}
        return result
    }

    public func getImagesAsync(tag: TagEntity, onComplete: @escaping(_ images: [ImageEntity]) -> Void) -> Void {
        DispatchQueue.global().async {[unowned self] in
            let result = self.getImages(tag: tag)
            
            onComplete(result)
        }
    }
    
    public func getImagesSync(tag: TagEntity) -> [ImageEntity] {
        return getImages(tag: tag)
    }
    
    private func remove(localIdentifiers: [String]) -> Void {
        for localIdentifier in localIdentifiers {
//            print("removed: \(localIdentifier)")
            _ = _actualImages.removeValue(forKey: localIdentifier)
            _ = _taggedImages.removeValue(forKey: localIdentifier)
        }
        _imageRepository.remove(localIdentifiers: localIdentifiers)
    }
    
    private func addAssets(assets: [PHAsset]) -> Void {
        if assets.isEmpty {
            return
        }
        for asset in assets {
//            print("added: \(asset.localIdentifier)")
            let imageEntity = createImage(asset: asset)
            _actualImages[imageEntity.localIdentifier] = imageEntity
        }
    }
    
    private func getImages(tag: TagEntity) -> [ImageEntity]{
        
        var result = [ImageEntity]()
        
        if(tag.isAll){
            result = _actualImages.values.toArray()
        }
        else if(tag.isUntagged){
            result = _actualImages.values.toArray()
        }
            
        else if(_taggedImages.isEmpty){
            result = [ImageEntity]()
        }
        else{
            result = Array(_taggedImages.values.filter{$0.containsTag(tagId: tag.id)})
        }
        result.sort{$0.creationDate ?? Date() > $1.creationDate ?? Date()}
        
        return result
    }
    
    func saveOrUpdate(entities: [ImageEntity]) -> Void {
        
        entities.forEach{_tagCache.saveOrUpdate(tags: $0.newTags)}
        let imageChanges = _imageRepository.saveOrUpdate(entities)
        
        imageChanges.add.forEach { item in
            _taggedImages[item.localIdentifier] = item
            _actualImages[item.localIdentifier] = item
//            _actualImages.removeValue(forKey: item.localIdentifier)
        }
        
        imageChanges.remove.forEach{ item in
            _taggedImages.removeValue(forKey: item.localIdentifier)
            _actualImages[item.localIdentifier] = item
        }
        
        for entity in entities {
            let tagChanges = entity.tagChanges()
            _imageRepository.remove(tagImages: tagChanges.removeIds)
            let tagImages = _imageRepository.addTagImage(imageId: entity.id, entities: tagChanges.add)
            entity.appendTagId(entities: tagImages)
        }
    }
    
    private func syncImages() -> Void {
        for image in _taggedImages.values {
            if _actualImages.keys.contains(image.localIdentifier){
                _actualImages[image.localIdentifier] = image
            }
        }
    }
    
    private func getAssets(_ fetchResult: PHFetchResult<PHAsset>) -> [PHAsset]{
        var assets: [PHAsset] = []
        
        fetchResult.enumerateObjects(using: {(asset, id, _) in
            assets.append(asset)            
        })
        return assets
    }
    
    private func createImage(asset: PHAsset) -> ImageEntity {
        return ImageEntity(localIdentifier: asset.localIdentifier, creationDate: asset.creationDate)
    }
}

