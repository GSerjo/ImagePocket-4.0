//
//  TagImageEntity.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 9/3/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

final class TagImageEntity: Entity {
    var id: Int64
    var tagId: Int64
    
    init(id: Int64 = 0, tagId: Int64 = 0){
        self.id = id
        self.tagId = tagId
    }
    
    func clone() -> TagImageEntity {
        return TagImageEntity(id: id, tagId: tagId)
    }
}
