//
//  Entity.swift
//  ImagePocket
//
//  Created by Serjo on 03/11/2016.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation

protocol Entity {
    var id: Int64 { get }
}

extension Entity {
    
    var isNew: Bool {
        return id == 0
    }
    
}
