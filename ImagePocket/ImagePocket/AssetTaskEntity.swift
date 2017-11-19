//
//  AssetTask.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/18/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import CoreLocation

enum AssetTaskStatus {
    case forGeoSearch
    case forReady
    case ready
}


final class AssetTaskEntity : Entity {
    
    var id: Int64 = 0
    private(set) var localIdentifier: String
    private (set) var geoHash: String? = String.empty
    let latitude: Double?
    let longitude: Double?
    private(set) var text = String.empty
    private(set) var status: AssetTaskStatus
    
    init?(_ localIdentifier: String, _ location: CLLocation?, _ creationDate: Date?) {
        if location == nil && creationDate == nil {
            return nil
        }
        self.localIdentifier = localIdentifier
        
        if let coordinate = location?.coordinate {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            geoHash = Geohash.encode(latitude: latitude!, longitude: longitude!, precision: 5)
            status = .forGeoSearch
    
        } else {
            latitude = nil
            longitude = nil
            status = .forReady
        }
        
        if let date = creationDate {
            text = getDateFormatter().string(from: date)
        }
    }

    private func getDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy LLLL"
        return dateFormatter
    }
}
