//
//  GeoHashEntity.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/14/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

final class GeoHashEntity: Entity {
    var id: Int64
    let geoHash: String
    private(set) var processed = false
    private(set) var address: String?
    
    init(id: Int64, geoHash: String) {
        self.id = id
        self.geoHash = geoHash
    }
    
    func setAddress(_ address: String) -> Void {
        self.address = address
        processed = true
    }
}
