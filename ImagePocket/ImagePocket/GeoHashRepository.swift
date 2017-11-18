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
    private let _chunkSize = 10
    
    private init(){
    }
    
    func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true){ t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.geoHash)
            t.column(Columns.processed)
            t.column(Columns.adderess)
            t.column(Columns.latitude)
            t.column(Columns.longitude)
        }
        
        let indexQuery = _table.createIndex([Columns.geoHash], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    func save(entities: [GeoHashEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            for entity in entities {
                let query = self._table.insert(Columns.adderess <- String.empty, Columns.processed <- false, Columns.geoHash <- entity.geoHash, Columns.latitude <- entity.latitude, Columns.longitude <- entity.longitude)
                let _ = try? DataStore.instance.db.run(query)
            }
        }
    }
    
    func updateProcessed(entities: [GeoHashEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        let processedEntities = entities.filter{$0.processed}
        for entity in processedEntities {
            let query = _table.filter(Columns.id == entity.id)
            let _ = try? DataStore.instance.db.run(query.update(Columns.adderess <- entity.address, Columns.processed <- true))
        }
    }
    
    func updateProcessed(entity: GeoHashEntity) -> Void {
        if entity.processed {
            print(entity)
            let query = _table.filter(Columns.id == entity.id)
            let _ = try? DataStore.instance.db.run(query.update(Columns.adderess <- entity.address, Columns.processed <- true))
        }
    }
    
    func getUnprocessedChunk() -> [GeoHashEntity] {
        
        var result = [GeoHashEntity]()
        
        let query = _table.filter(Columns.processed == false).limit(_chunkSize)
        if let rows = try? DataStore.instance.db.prepare(query){
            rows.forEach{ row in
                let item = GeoHashEntity(id: row[Columns.id], geoHash: row[Columns.geoHash], latitude: row[Columns.latitude], longitude: row[Columns.longitude])
                result.append(item)
            }
        }
        return result
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let geoHash = Expression<String>("geoHash")
        static let processed = Expression<Bool>("processed")
        static let adderess = Expression<String>("address")
        static let latitude = Expression<Double>("latitude")
        static let longitude = Expression<Double>("longitude")
    }
}

