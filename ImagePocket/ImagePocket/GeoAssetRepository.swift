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
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
        static let geoHash = Expression<String>("geoHash")
    }
}
