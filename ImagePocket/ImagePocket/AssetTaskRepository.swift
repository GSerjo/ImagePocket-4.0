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
    
    private init(){
    }
    
    func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true){ t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.creationDate)
            t.column(Columns.localIdentifier)
            t.column(Columns.geoHash)
            t.column(Columns.address)
            t.column(Columns.latitude)
            t.column(Columns.longitude)
            t.column(Columns.status)
        }
        
        let indexQuery = _table.createIndex([Columns.localIdentifier, Columns.geoHash], unique: true, ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    public func save(_ entities: [AssetTaskEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            for entity in entities {
                
                let query = self._table.insert(or: .ignore,
                    Columns.creationDate <- entity.creationDate,
                    Columns.localIdentifier <- entity.localIdentifier,
                    Columns.geoHash <- entity.geoHash,
                    Columns.latitude <- entity.latitude,
                    Columns.longitude <- entity.longitude,
                    Columns.address <- entity.address,
                    Columns.status <- entity.status.rawValue)
                
                let _ = try? DataStore.instance.db.run(query)
                AssetRespository.instance.save(entity)
            }
        }
    }
    
    public func save(entity: AssetTaskEntity) -> Void {
        let query = _table.insert(or: .ignore,
            Columns.creationDate <- entity.creationDate,
            Columns.localIdentifier <- entity.localIdentifier,
            Columns.geoHash <- entity.geoHash,
            Columns.latitude <- entity.latitude,
            Columns.longitude <- entity.longitude,
            Columns.address <- entity.address,
            Columns.status <- entity.status.rawValue)
    
        let _ = try? DataStore.instance.db.run(query)
    }
    
    public func updateAddress(_ entity: AssetTaskEntity) -> Void {
        
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            let query = self._table.filter(Columns.id == entity.id)
            let _ = try? DataStore.instance.db.run(query.update(Columns.status <- entity.status.rawValue, Columns.address <- entity.address))
            
            if entity.isForReady && entity.address != nil && entity.geoHash != nil {
                GeoHashRepository.instance.save(entity: GeoHashEntity(geoHash: entity.geoHash!, address: entity.address!))
            }
        }
    }
    
    public func markAsReady(_ entities: [AssetTaskEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        
        let ids = entities.map{$0.id}
        let searchEntities = entities.map{SearchEntity(text: $0.text, localIdentifier: $0.localIdentifier)}
        
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            for searchEntity in searchEntities {
                SearchRepository.instance.save(entity: searchEntity)
            }
            
            let query = self._table.filter(ids.contains(Columns.id))
            let _ = try? DataStore.instance.db.run(query.update(Columns.status <- AssetTaskStatus.ready.rawValue))
        }
    }
    
    public func markAsReady(_ entity: AssetTaskEntity) -> Void {
        let searchEntity = SearchEntity(text: entity.text, localIdentifier: entity.localIdentifier)
        
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            SearchRepository.instance.save(entity: searchEntity)

            let query = self._table.filter(Columns.id == entity.id)
            let _ = try? DataStore.instance.db.run(query.update(Columns.status <- AssetTaskStatus.ready.rawValue))
        }
    }
    
    public func removeReady() -> Void {
        let query = _table.filter(Columns.status == AssetTaskStatus.ready.rawValue)
        let _ = try? DataStore.instance.db.run(query.delete())
    }
    
    public func getForGeoSearchChunk() -> [AssetTaskEntity] {
        return getByStatus(status: .forGeoSearch, chunkSize: _forGeoSearchChunkSize)
    }
    
    public func getForReady() -> [AssetTaskEntity] {
        return getByStatus(status: .forReady)
    }
    
    private func getByStatus(status: AssetTaskStatus, chunkSize: Int? = nil) -> [AssetTaskEntity] {
        var result = [AssetTaskEntity]()
        
        let query = _table.filter(Columns.status == status.rawValue).limit(chunkSize)
        if let rows = try? DataStore.instance.db.prepare(query){
            rows.forEach{ row in
                
                let item = AssetTaskEntity(
                    id: row[Columns.id],
                    creationDate: row[Columns.creationDate],
                    localIdentifier: row[Columns.localIdentifier],
                    geoHash: row[Columns.geoHash],
                    latitude: row[Columns.latitude],
                    longitude: row[Columns.longitude],
                    address: row[Columns.address],
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
        static let address = Expression<String?>("address")
        static let creationDate = Expression<String?>("creationDate")
        static let status = Expression<Int>("status")
    }
}
