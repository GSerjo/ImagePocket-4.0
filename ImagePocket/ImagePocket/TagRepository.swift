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
    
    private static let _tableName = "Tag"
    private static let _table = Table(_tableName)
    
    static func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true){ t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.name)
        }
        
        let indexQuery = _table.createIndex([Columns.name], ifNotExists: true)
        
        try DataStore.sharedInstance.db.run(tableQuery)
        try DataStore.sharedInstance.db.run(indexQuery)
    }
    
    func saveOrUpdate(values: [TagEntity]) -> Void {
        
        values.forEach { item in
            let query = TagRepository._table.insert(Columns.name <- item.name)
            if let id  = try? DataStore.sharedInstance.db.run(query){
                item.id = id
            }
        }
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let name = Expression<String>("name")
    }
}
