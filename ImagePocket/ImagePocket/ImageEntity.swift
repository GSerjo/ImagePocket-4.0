//
//  ImageEntity.swift
//  ImagePocket
//
//  Created by Serjo on 30/10/2016.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation

final class ImageEntity: Entity {
    
    private var _tags = [TagEntity]()
    
    var id: Int64
    private(set) var localIdentifier: String
    private(set) var creationDate: Date?
    private var _tagIds = [Int64]()
    
    init(id: Int64 = 0, localIdentifier: String, creationDate: Date?) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.creationDate = creationDate
    }
    
    var tags: [TagEntity] {
        return _tags
    }
    
    func addTag(_ tag: TagEntity) {
        _tags.append(tag)
    }
    
    func appendTagId(id: Int64) {
        _tagIds.append(id)
    }
    
    func replaceTags(tags: [TagEntity]) {
        _tags = tags
    }
    
}
