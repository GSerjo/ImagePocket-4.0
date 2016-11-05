//
//  TagEntity.swift
//  ImagePocket
//
//  Created by Serjo on 29/10/2016.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation



final class TagEntity : Equatable, Entity {
    
    static func ==(left: TagEntity, right: TagEntity) -> Bool{
        return left.id == right.id
    }
    
    static let all = TagEntity(id: -1, name: "All")
    static let untagged = TagEntity(id: -2, name: "Untagged")
    
    init(id: Int64 = 0, name: String) {
        self.id = id
        self.name = name
    }
    
    var isAll: Bool{
        return self == TagEntity.all
    }
    
    
    var isUntagged: Bool{
        return self == TagEntity.untagged
    }
    
    var isUser: Bool {
        return !self.isAll && !self.isUntagged
    }
    
    var id: Int64
    var name: String = String.empty
}
