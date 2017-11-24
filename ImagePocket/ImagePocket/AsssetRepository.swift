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
        
        let indexQuery = _table.createIndex([Columns.localIdentifier], unique: true, ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    public func save(_ entity: AssetTaskEntity) -> Void {
        let query = _table.insert(or: .ignore,
            Columns.creationDate <- entity.creationDate,
            Columns.localIdentifier <- entity.localIdentifier,
            Columns.latitude <- entity.latitude,
            Columns.longitude <- entity.longitude)
        
        let _ = try? DataStore.instance.db.run(query)
    }
    
    public func getChanges(tasks: [AssetTaskable]) -> Void {
        
        if tasks.isEmpty {
            return
        }
        
        let newAssets = Set(tasks.map{AssetInternal(task: $0)})
        var currentAssets = Set<AssetInternal>()
        
        let query = _table.select(Columns.localIdentifier)
        if let rows = try? DataStore.instance.db.prepare(query){
            for row in rows {
                currentAssets.insert(AssetInternal(localIdentifier: row[Columns.localIdentifier]))
            }
        }
        
        let removed = Array(currentAssets.subtracting(currentAssets)).map{$0.localIdentifier}
        let added = Array(newAssets.subtracting(currentAssets))
        
        let _ = try? DataStore.instance.db.transaction {[unowned self] in
            if removed.isEmpty == false {
                let query = self._table.filter(removed.contains(Columns.localIdentifier))
                let _ = try? DataStore.instance.db.run(query.delete())
            }
            
            if added.isEmpty == false {
                for item in added {
                    let query = self._table.insert(or: .ignore,
                                              Columns.creationDate <- item.creationDateText,
                                              Columns.localIdentifier <- item.localIdentifier,
                                              Columns.latitude <- item.latitude,
                                              Columns.longitude <- item.longitude)
                    
                    let _ = try? DataStore.instance.db.run(query)
                    
                    if let assetTask = AssetTaskEntity(task: item) {
                        AssetTaskResitory.instance.save(entity: assetTask)
                    }
                }
            }
        }
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
        static let latitude = Expression<Double?>("latitude")
        static let longitude = Expression<Double?>("longitude")
        static let creationDate = Expression<String?>("creationDate")
    }
    
    private class AssetInternal: Hashable, AssetTaskable {
        
        private(set) var localIdentifier: String
        private(set) var creationDate: Date?
        private(set) var latitude: Double?
        private(set) var longitude: Double?
        
        init(task: AssetTaskable) {
            localIdentifier = task.localIdentifier
            creationDate = task.creationDate
            latitude = task.latitude
            longitude = task.longitude
        }
        
        init(localIdentifier: String) {
            self.localIdentifier = localIdentifier
        }
        
        static func ==(left: AssetInternal, right: AssetInternal) -> Bool{
            return left.localIdentifier == right.localIdentifier
        }
        
        var hashValue: Int {
            return localIdentifier.hashValue
        }
    }
}
