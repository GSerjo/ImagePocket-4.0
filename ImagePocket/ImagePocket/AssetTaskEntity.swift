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

protocol AssetTaskable {
    var localIdentifier: String { get }
    var creationDate: Date? { get }
    var latitude: Double? { get }
    var longitude: Double? { get }
}

extension AssetTaskable {
    var creationDateText: String? {
        get {
            if let date = self.creationDate{
                return getDateFormatter().string(from: date)
            }
            return nil
        }
    }
    
    private func getDateFormatter() -> DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy LLLL"
        return dateFormatter
    }
}

extension AssetTaskEntity: Hashable {
    static func ==(left: AssetTaskEntity, right: AssetTaskEntity) -> Bool{
        return left.geoHash == right.geoHash
    }
    
    var hashValue: Int {
        if geoHash == nil {
            return 0
        }
        return geoHash!.hashValue
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
    
    init?(task: AssetTaskable) {
        let hasLocation = task.latitude != nil && task.longitude != nil
        if hasLocation && task.creationDate == nil {
            return nil
        }
        self.localIdentifier = task.localIdentifier
        
        if hasLocation{
            self.latitude = task.latitude
            self.longitude = task.longitude
            geoHash = Geohash.encode(latitude: latitude!, longitude: longitude!, precision: 5)
            status = .forGeoSearch
            
        } else {
            latitude = nil
            longitude = nil
            status = .forReady
        }
        
        if let date = task.creationDate {
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
    
    var isForReady: Bool {
        return status == .forReady
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
