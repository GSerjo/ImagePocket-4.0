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
    
    var context: String? {
        if mediaType == .video {
            return "video"
        }
        return nil
    }
    
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
    private var _assets = [String: PHAsset]()
    private let _tagCache = TagCache.instance
    private let _searchCache = SearchCache.instance
    var fetchResult: PHFetchResult<PHAsset>!
    
    subscript(localIdentifier: String) -> PHAsset?{
        return _assets[localIdentifier]
    }
    
    subscript(localIdentifiers: [String]) -> [PHAsset]{
        return localIdentifiers.map{self[$0]}.flatMap{$0}
    }
    
    func startAsync(onComplete: @escaping () -> Void) -> Void {
        DispatchQueue.global().async {[unowned self] in
            self._taggedImages = self._imageRepository.getAll().toDictionary{$0.localIdentifier}
            
            let allPhotosOptions = PHFetchOptions()
            allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            self.fetchResult = PHAsset.fetchAssets(with: allPhotosOptions)
            
            self._assets = self.getAssets(self.fetchResult).toDictionary{$0.localIdentifier}
            AssetTaskProcessor.instance.initTasks(tasks: self._assets.values.toArray())
            
            self._actualImages  = self._assets.values.map(self.createImage).toDictionary{$0.localIdentifier}
            
            self.syncImages()
            
            onComplete()
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
    
    public func remove(localIdentifiers: [String]) -> Void {
        for localIdentifier in localIdentifiers {
            _ = _actualImages.removeValue(forKey: localIdentifier)
            _ = _taggedImages.removeValue(forKey: localIdentifier)
            _ = _assets.removeValue(forKey: localIdentifier)
        }
        _imageRepository.remove(localIdentifiers: localIdentifiers)
    }
    
    public func saveOrUpdate(entities: [ImageEntity]) -> Void {
        
        entities.forEach{_tagCache.saveOrUpdate(tags: $0.newTags)}
        let imageChanges = _imageRepository.saveOrUpdate(entities)
        
        imageChanges.add.forEach { item in
            _taggedImages[item.localIdentifier] = item
            _actualImages[item.localIdentifier] = item
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
    
    public func removeTagFromImages(tags: [TagEntity]) -> Void {
        if tags.isEmpty {
            return
        }
        let removedTagImages = _imageRepository.remove(tags: tags)
        _tagCache.remove(tags: tags)
        let updatedImages = _imageRepository.getBy(ids: removedTagImages.map{$0.imageId})
        for image in updatedImages {
            _taggedImages[image.localIdentifier]?.removeTagId(entities: removedTagImages)
        }
    }
    
    public func updateTagFromImages(tags: [TagEntity]) -> Void {
        if tags.isEmpty {
            return
        }
        _tagCache.saveOrUpdate(tags: tags)
    }
    
    private func addAssets(assets: [PHAsset]) -> Void {
        if assets.isEmpty {
            return
        }
        for asset in assets {
            let imageEntity = createImage(asset: asset)
            _actualImages[imageEntity.localIdentifier] = imageEntity
            _assets[imageEntity.localIdentifier] = asset
        }
    }
    
    private func getImages(tag: TagEntity) -> [ImageEntity]{
        
        var result = [ImageEntity]()
        
        if tag.isAll {
            result = _actualImages.values.toArray()
        }
        else if tag.isUntagged {
            result = _actualImages.values.filter{$0.hasTags == false}
        }
        else if _taggedImages.isEmpty {
            result = [ImageEntity]()
        }
        else {
            result = Array(_taggedImages.values.filter{$0.containsTag(tagId: tag.id)})
        }
        result.sort{$0.creationDate ?? Date() > $1.creationDate ?? Date()}
        
        return result
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

