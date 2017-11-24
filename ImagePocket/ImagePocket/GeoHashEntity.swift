//
//  GeoHashEntity.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/14/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

final class GeoHashEntity: Entity, CustomStringConvertible {
    
    var description: String {
        return address.isEmpty() ? "empty address": address
    }
    
    var id: Int64
    let geoHash: String
    private(set) var address: String
    
    
    init(geoHash: String, address: String) {
        self.geoHash = geoHash
        self.address = address
        id = 0
    }
}
