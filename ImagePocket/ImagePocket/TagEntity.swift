//
//  TagEntity.swift
//  ImagePocket
//
//  Created by Serjo on 29/10/2016.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation

func ==(left: TagEntity, right: TagEntity) -> Bool{
    return left.id == right.id
}

struct TagEntity : Equatable {
    
    static let all = TagEntity(id: -1, name: "All")
    static let untagged = TagEntity(id: -2, name: "Untagged")
    
    var isAll: Bool{
        return self == TagEntity.all
    }
    
    
    var isUntagged: Bool{
        return self == TagEntity.untagged
    }
    
    
    
    var id: Int64
    var name: String = String.empty
}
