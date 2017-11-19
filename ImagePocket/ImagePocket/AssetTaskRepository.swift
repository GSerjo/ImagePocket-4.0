//
//  AssetTaskRepository.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/18/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import SQLite

final class AssetTaskResitory {
    private let _table = Table("AssetTask")
    static let instance = AssetTaskResitory()
    
    private init(){
    }
    
    func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true){ t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.localIdentifier)
            t.column(Columns.geoHash)
            t.column(Columns.latitude)
            t.column(Columns.longitude)
        }
        
        let indexQuery = _table.createIndex([Columns.localIdentifier, Columns.geoHash], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
        static let geoHash = Expression<String>("geoHash")
        static let latitude = Expression<Double?>("latitude")
        static let longitude = Expression<Double?>("longitude")
        static let text = Expression<String>("text")
        static let status = Expression<Int>("status")
    }
}
