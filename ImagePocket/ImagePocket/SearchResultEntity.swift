//
//  SearchResultEntity.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/1/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

struct SearchResultEntity {
    
    public let localIdentifier: String
    
    init(_ localIdentifier: String) {
        self.localIdentifier = localIdentifier
    }
}
