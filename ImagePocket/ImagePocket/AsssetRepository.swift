//
//  AsssetRepository.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 11/23/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import SQLite

final class AssetRespository {
    
    private let _table = Table("CurrentAsset")
    static let instance = AssetRespository()
    
    private init(){
    }
    
    public func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true){ t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.creationDate)
            t.column(Columns.localIdentifier)
            t.column(Columns.latitude)
            t.column(Columns.longitude)
        }
        
        let indexQuery = _table.createIndex([Columns.localIdentifier], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    public func save(_ entity: AssetTaskEntity) -> Void {
        let query = _table.insert(
            Columns.creationDate <- entity.creationDate,
            Columns.localIdentifier <- entity.localIdentifier,
            Columns.latitude <- entity.latitude,
            Columns.longitude <- entity.longitude)
        
        let _ = try? DataStore.instance.db.run(query)
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
        static let latitude = Expression<Double?>("latitude")
        static let longitude = Expression<Double?>("longitude")
        static let creationDate = Expression<String?>("creationDate")
    }
}
