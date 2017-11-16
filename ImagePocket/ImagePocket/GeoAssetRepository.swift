//
//  GeoAssetRepository.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/10/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import SQLite


final class GeoAssetRepository {
    private let _table = Table("GeoAsset")
    static let instance = GeoAssetRepository()

    private init(){
    }
    
    func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true){ t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.localIdentifier)
            t.column(Columns.geoHash)
        }
        
        let indexQuery = _table.createIndex([Columns.localIdentifier, Columns.geoHash], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    func save(entities: [GeoAssetEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            for entity in entities {
                let query = self._table.insert(Columns.localIdentifier <- entity.localIdentifier, Columns.geoHash <- entity.geoHash, Columns.latitude <- entity.latitude, Columns.longitude <- entity.longitude)
                let _ = try? DataStore.instance.db.run(query)
            }
        }
    }
    
    func getUniqueGeoHashes() -> [GeoAssetEntity] {
        var result = [GeoAssetEntity]()
        if let rows = try? DataStore.instance.db.prepare(_table.group([Columns.geoHash])){
            rows.forEach{ row in
                let entity = GeoAssetEntity(row[Columns.localIdentifier], row[Columns.geoHash], row[Columns.latitude], row[Columns.longitude])
                result.append(entity)
            }
        }
        return result
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
        static let geoHash = Expression<String>("geoHash")
        static let latitude = Expression<Double>("latitude")
        static let longitude = Expression<Double>("longitude")
    }
}
