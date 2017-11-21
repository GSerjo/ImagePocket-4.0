//
//  AssetTask.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/18/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import CoreLocation

enum AssetTaskStatus: Int {
    case forGeoSearch
    case forReady
    case ready
}


extension AssetTaskEntity: Hashable {
    static func ==(left: AssetTaskEntity, right: AssetTaskEntity) -> Bool{
        return left.address == right.address
    }
    
    var hashValue: Int {
        return id.hashValue
    }
}

final class AssetTaskEntity : Entity {
    
    var id: Int64 = 0
    private(set) var localIdentifier: String
    private (set) var geoHash: String? = String.empty
    let latitude: Double?
    let longitude: Double?
    private(set) var status: AssetTaskStatus
    private(set) var address: String?
    private(set) var creationDate: String?
    
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
            self.creationDate = getDateFormatter().string(from: date)
        }        
    }
    
    init(id: Int64, creationDate: String?, localIdentifier: String, geoHash: String?, latitude: Double?, longitude: Double?, address: String?, status: AssetTaskStatus) {
        self.creationDate = creationDate
        self.id = id
        self.localIdentifier = localIdentifier
        self.geoHash = geoHash
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.status = status
    }
    
    var text: String {
        if address == nil && creationDate == nil {
            return String.empty
        }
        if address != nil && creationDate != nil {
            return address! + " " + creationDate!
        }
        if address == nil {
            return creationDate!
        }
        return address!
    }
    
    var isReady: Bool {
        return status == .ready
    }
    
    public func setAddress(_ items: [String]) -> Void {
        status = .forReady
        if items.isEmpty {
            return
        }
        setAddress(address: items.joined(separator: " "))
    }
    
    public func setAddress(address: String) -> Void {
        status = .forReady
        self.address = address
    }

    private func getDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy LLLL"
        return dateFormatter
    }
}
