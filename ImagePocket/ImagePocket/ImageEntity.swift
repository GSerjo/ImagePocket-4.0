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
    private(set) var tagIds: [TagImageEntity]
    private(set) var newTags = [TagEntity]()
    private var _tags = [TagEntity]()
    
    init(id: Int64 = 0, localIdentifier: String, creationDate: Date?, tagIds: [TagImageEntity] = []) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
        self.tagIds = tagIds
    }
    
    var tags: [TagEntity] {
        let tags = tagIds.map{_tagCache.getById(tagId: $0.tagId)}.flatMap{$0}
        return tags
    }
    
    func clone() -> ImageEntity {
        let tagIds = self.tagIds.map{$0.clone()}
        return ImageEntity(id: id, localIdentifier: localIdentifier, creationDate: creationDate, tagIds: tagIds)
    }
    
    func appendTagId(entity: TagImageEntity) {
        tagIds.append(entity)
    }
    
    func replaceTags(tags: [TagEntity]) {
        newTags = tags
    }
    
    func tagChanges() -> (removeIds:[TagImageEntity], add: [TagEntity]) {
        let dummy = tagIds.toDictionary { (item: TagImageEntity) -> Int64 in
            item.tagId
        }
        
        var add = [TagEntity]()
        
        for item in newTags {
            if !dummy.keys.contains(item.id){
                add.append(item)
            }
        }
        
        return ([], add)
    }
    
}
