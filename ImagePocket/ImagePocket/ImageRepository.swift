//
//  ImageRepository.swift
//  ImagePocket
//
//  Created by Serjo on 22/10/16.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation
import SQLite

final class ImageRepository {
    
    private let _table = Table("Image")
    public static let shareInstance = ImageRepository()
    
    func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.localIdentifier)
        }
        
        let indexQuery = _table.createIndex([Columns.localIdentifier], ifNotExists: true)
        
        try DataStore.sharedInstance.db.run(tableQuery)
        try DataStore.sharedInstance.db.run(indexQuery)
    }
    
    func getAll() -> [ImageEntity] {
        var result = [ImageEntity]()
        
        if let rows = try? DataStore.sharedInstance.db.prepare(_table){
            rows.forEach{ row in
                let item = ImageEntity(id: row[Columns.id], localIdentifier: row[Columns.localIdentifier])
                result.append(item)
            }
        }
        return result
    }
    
    func remove(_ entities: [ImageEntity]) -> Void {
        _ = _table.filter(entities.map {$0.id}.contains(Columns.id)).delete()
    }
    
    func saveOrUpdate(_ entities: [ImageEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        
        let forRemove = entities.filter{ x in
            x.isNew == false && x.tags.isEmpty
        }
        let forAddOrUpdate = entities.filter { x in
            x.tags.isEmpty == false
        }
        remove(forRemove)
        addOrUpdate(forAddOrUpdate)
    }
    
    private func addOrUpdate(_ entities: [ImageEntity]) -> Void {
        entities.forEach{ entity in
            if entity.isNew {
                let query = _table.insert(Columns.localIdentifier <- entity.localIdentifier)
                if let id  = try? DataStore.sharedInstance.db.run(query){
                    entity.id = id
                }
            }
        }
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
    }
    
}
