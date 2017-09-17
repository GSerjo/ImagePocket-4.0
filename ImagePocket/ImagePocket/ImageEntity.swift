//
//  ImageEntity.swift
//  ImagePocket
//
//  Created by Serjo on 30/10/2016.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation

final class ImageEntity: Entity {
    
    private let _tagCache = TagCache.instance
    
    var id: Int64
    private(set) var localIdentifier: String
    private(set) var creationDate: Date?
    private var _tagIds: [Int64: TagImageEntity]
    private(set) var newTags = [TagEntity]()
    
    init(id: Int64 = 0, localIdentifier: String, creationDate: Date?, tagIds: [Int64: TagImageEntity] = [Int64: TagImageEntity]()) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
        _tagIds = tagIds
    }
    
    var tags: [TagEntity] {
        let tags = _tagIds.values.toArray().map{self._tagCache.getById(tagId: $0.tagId)}.flatMap{$0}
        return tags
    }
    
    var hasTags: Bool {
        return !newTags.isEmpty || !_tagIds.isEmpty
    }
    
    func hasSearchableText(text: String) -> Bool {
        if !hasTags {
            return false
        }
        for item in tags {
            if item.name.contains(text) {
                return true
            }
        }
        return false
    }
    
    func clone() -> ImageEntity {
        let tagIds = _tagIds.values.map{$0.clone()}.toDictionary{ (item: TagImageEntity) -> Int64 in
            item.tagId
        }
        return ImageEntity(id: id, localIdentifier: localIdentifier, creationDate: creationDate, tagIds: tagIds)
    }
    
    func containsTag(tagId: Int64) -> Bool {
        return _tagIds.keys.contains(tagId)
    }
    
    func appendTagId(entity: TagImageEntity) {
        _tagIds[entity.tagId] = entity
    }
    
    func appendTagId(entities: [TagImageEntity]){
        if entities.isEmpty {
            return
        }

        for item in entities {
            _tagIds[item.tagId] = item
        }
    }
    
    func replaceTags(tags: [TagEntity]) {
        newTags = tags
    }
    
    func tagChanges() -> (removeIds:[TagImageEntity], add: [TagEntity]) {
        
        var add = [TagEntity]()
        
        for item in newTags {
            if !_tagIds.keys.contains(item.id){
                add.append(item)
            }
        }
        
        let dummy = newTags.toDictionary{ (item: TagEntity) -> Int64 in
            item.id
        }
        
        var remove = [TagImageEntity]()
        
        for item in _tagIds.values {
            if !dummy.keys.contains(item.tagId) {
                remove.append(item)
            }
        }
        
        for item in remove {
            _tagIds.removeValue(forKey: item.tagId)
        }
        
        return (remove, add)
    }
    
}
