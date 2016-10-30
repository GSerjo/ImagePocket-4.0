//
//  ImageEntity.swift
//  ImagePocket
//
//  Created by Serjo on 30/10/2016.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation

struct ImageEntity {
    
    private var _tags = [TagEntity]()
    
    var id: Int64
    var localIdentifier: String
    
    
    mutating func addTag(_ tag: TagEntity) {
        _tags.append(tag)
    }
    
}
