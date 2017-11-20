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
    private(set) var address = String.empty
    
    init(id: Int64 = 0, geoHash: String) {
        self.id = id
        self.geoHash = geoHash
    }
    
    init(geoHash: String, address: String) {
        self.geoHash = geoHash
        self.address = address
        id = 0
    }
    
    func setAddress(_ addressItems: [String]) -> Void {
        address = addressItems.joined(separator: " ")
    }
}
