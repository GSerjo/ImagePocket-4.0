//
//  GeoHashRepository.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/10/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import SQLite

final class GeoHashRepository {
    private let _table = Table("GeoHash")
    static let instance = GeoHashRepository()
    
    private init(){
    }
    
    func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true){ t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.geoHash)
            t.column(Columns.adderess)
        }
        
        let indexQuery = _table.createIndex([Columns.geoHash], unique: true, ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    public func get(geoHash: String) -> GeoHashEntity? {
        let query = _table.filter(Columns.geoHash == geoHash)
        
        if let rows = try? DataStore.instance.db.prepare(query) {
            for row in rows {
                return GeoHashEntity(geoHash: row[Columns.geoHash], address: row[Columns.adderess])
            }
        }
        return nil
    }
    
    public func save(entity: GeoHashEntity) -> Void {
        let query = self._table.insert(or: .ignore, Columns.adderess <- entity.address, Columns.geoHash <- entity.geoHash)
        _ = try? DataStore.instance.db.run(query)
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let geoHash = Expression<String>("geoHash")
        static let adderess = Expression<String>("address")
    }
}

