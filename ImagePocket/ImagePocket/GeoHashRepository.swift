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
            t.column(Columns.processed)
            t.column(Columns.adderess)
        }
        
        let indexQuery = _table.createIndex([Columns.geoHash], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    func save(geoHashes: [String]) -> Void {
        if geoHashes.isEmpty {
            return
        }
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            for geoHash in geoHashes {
                let query = self._table.insert(Columns.adderess <- String.empty, Columns.processed <- false, Columns.geoHash <- geoHash)
                let _ = try? DataStore.instance.db.run(query)
            }
        }
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let geoHash = Expression<String>("geoHash")
        static let processed = Expression<Bool>("processed")
        static let adderess = Expression<String>("address")
    }
}

