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
    private let _forGeoSearchChunkSize = 10
    private let _forReadyChunkSize = 100
    
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
    
    public func save(_ entities: [AssetTaskEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            for entity in entities {
                
                let query = self._table.insert(
                    Columns.localIdentifier <- entity.localIdentifier,
                    Columns.geoHash <- entity.geoHash,
                    Columns.latitude <- entity.latitude,
                    Columns.longitude <- entity.longitude,
                    Columns.text <- entity.text,
                    Columns.status <- entity.status.rawValue)
                
                let _ = try? DataStore.instance.db.run(query)
            }
        }
    }
    
    public func update(_ entity: AssetTaskEntity) -> Void {
        let query = _table.filter(Columns.id == entity.id)
        let _ = try? DataStore.instance.db.run(query.update(Columns.status <- entity.status.rawValue, Columns.text <- entity.text))
    }
    
    public func updateStatus(_ entities: [AssetTaskEntity], status: AssetTaskStatus) -> Void {
        if entities.isEmpty {
            return
        }
        
        let ids = entities.map{$0.id}
        let query = _table.filter(ids.contains(Columns.id))
        let _ = try? DataStore.instance.db.run(query.update(Columns.status <- status.rawValue))
    }
    
    public func removeReady() -> Int? {
        let query = _table.filter(Columns.status == AssetTaskStatus.ready.rawValue)
        return try? DataStore.instance.db.run(query.delete())
    }
    
    public func remove(_ entities: [AssetTaskEntity]) -> Void {
        let ids = entities.map{$0.id}
        let query = _table.filter(ids.contains(Columns.id))
        let _ = try? DataStore.instance.db.run(query.delete())
    }
    
    public func getForGeoSearchChunk() -> [AssetTaskEntity] {
        return getByStatus(status: .forGeoSearch, chunkSize: _forGeoSearchChunkSize)
    }
    
    public func getForReadyChunk() -> [AssetTaskEntity] {
        return getByStatus(status: .forReady, chunkSize: _forReadyChunkSize)
    }
    
    private func getByStatus(status: AssetTaskStatus, chunkSize: Int) -> [AssetTaskEntity] {
        var result = [AssetTaskEntity]()
        
        let query = _table.filter(Columns.status == status.rawValue).limit(chunkSize)
        if let rows = try? DataStore.instance.db.prepare(query){
            rows.forEach{ row in
                
                let item = AssetTaskEntity(
                    id: row[Columns.id],
                    localIdentifier: row[Columns.localIdentifier],
                    geoHash: row[Columns.geoHash],
                    latitude: row[Columns.latitude],
                    longitude: row[Columns.longitude],
                    text: row[Columns.text],
                    status: AssetTaskStatus(rawValue: row[Columns.status])!)
                
                result.append(item)
            }
        }
        return result
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
        static let geoHash = Expression<String?>("geoHash")
        static let latitude = Expression<Double?>("latitude")
        static let longitude = Expression<Double?>("longitude")
        static let text = Expression<String>("text")
        static let status = Expression<Int>("status")
    }
}
