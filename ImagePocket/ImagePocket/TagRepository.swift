//
//  TagRepository.swift
//  ImagePocket
//
//  Created by Serjo on 22/10/16.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation
import SQLite

final class TagRepository {
    
    private let _table = Table("Tag")
    static let instance = TagRepository()
    
    private init(){
    }
    
    func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true){ t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.name)
        }
        
        let indexQuery = _table.createIndex([Columns.name], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    func saveOrUpdate(_ values: [TagEntity]) -> Void {
        _ = try? DataStore.instance.db.transaction {[unowned self] in
            for tag in values {
                
                if tag.isNew {
                    let query = self._table.insert(Columns.name <- tag.name)
                    if let id  = try? DataStore.instance.db.run(query){
                        tag.id = id
                    }
                } else {
                    let query = self._table.filter(Columns.id == tag.id).update(Columns.name <- tag.name)
                    _ = try? DataStore.instance.db.run(query)
                }
            }
        }
    }
    
    func getAll() -> [TagEntity] {
        
        var result = [TagEntity]()
        
        if let rows = try? DataStore.instance.db.prepare(_table){
            rows.forEach{ row in
                let item = TagEntity(id: row[Columns.id], name: row[Columns.name])
                result.append(item)
            }
        }
        return result
    }
    
    func remove(_ tags: [TagEntity]) -> Void {
        _ = _table.filter(tags.map{ $0.id }.contains(Columns.id)).delete()
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let name = Expression<String>("name")
    }
}
