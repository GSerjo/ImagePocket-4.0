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
    
    init(id: Int64 = 0, localIdentifier: String) {
        self.id = id
        self.localIdentifier = localIdentifier
    }
    
    var tags: [TagEntity] {
        return _tags
    }
    
    func addTag(_ tag: TagEntity) {
        _tags.append(tag)
    }
    
}
