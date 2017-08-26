//
//  TagCache.swift
//  ImagePocket
//
//  Created by Serjo on 04/11/2016.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation


final class TagCache {
    
    private let _tagRepository = TagRepository.instance
    private var _tags = [Int64: TagEntity]()
    static let instance = TagCache()
    
    private init(){
        let tags = _tagRepository.getAll()
        
        if tags.count == 0 {
            fillTags()
        }
        
        _tags = _tagRepository.getAll().toDictionary{$0.id}
    }
    
    private func fillTags() -> Void{
        let tags = [TagEntity(name: "Test"), TagEntity(name: "Test1")]
        _tagRepository.saveOrUpdate(tags)
    }
    
    var tagCount: Int {
        return _tags.count
    }
    
    func contains(tagId: Int64) -> Bool {
        return _tags.keys.contains(tagId)
    }
    
    func getById(tagId: Int64) -> TagEntity? {
        return _tags[tagId]
    }
    
    var userTags: [TagEntity] {
        return _tags.values.toArray()
    }
    
    var allTags: [TagEntity] {
        var userTags = self.userTags.sorted(by: { $0.name < $1.name})
        userTags.insert(TagEntity.all, at: 0)
        userTags.insert(TagEntity.untagged, at: 1)
        return userTags
    }
    
}
