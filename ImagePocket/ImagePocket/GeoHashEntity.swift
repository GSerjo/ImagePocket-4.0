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
    private(set) var processed = false
    private(set) var address = String.empty
    let latitude: Double
    let longitude: Double
    
    init(id: Int64 = 0, geoHash: String, latitude: Double, longitude: Double) {
        self.id = id
        self.geoHash = geoHash
        self.latitude = latitude
        self.longitude = longitude
    }
    
    func setAddress(_ addressItems: [String]) -> Void {
        address = addressItems.joined(separator: " ")
        processed = true
    }
}
