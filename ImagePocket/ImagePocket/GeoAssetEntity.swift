//
//  GeoAssetEntity.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/9/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import CoreLocation


final class GeoAssetEntity {
    private(set) var localIdentifier: String
    private (set) var geoHash: String
    
    init?(_ localIdentifier: String, _ location: CLLocation?) {
        if let location = location {
            self.localIdentifier = localIdentifier
            let cooridate = location.coordinate
            self.geoHash = Geohash.encode(latitude: cooridate.latitude, longitude: cooridate.longitude, precision: 5)
        }
        else {
            return nil
        }
    }
    
    init(_ localIdentifier: String, _ geoHash: String) {
        self.localIdentifier = localIdentifier
        self.geoHash = geoHash
    }
}
