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
        
        try DataStore.sharedInstance.executeQuery(tableQuery)
        try DataStore.sharedInstance.executeQuery(indexQuery)
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let name = Expression<String>("name")
    }
}
