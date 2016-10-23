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
    
    private static let tableName = "Image"
    private static let table = Table(tableName)
    
    
    static func createTable() throws {
        
        let tableQuery = table.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.localIdentifier)
        }
        
        let indexQuery = table.createIndex([Columns.localIdentifier], ifNotExists: true)
        
        try DataStore.sharedInstance.executeQuery(tableQuery)
        try DataStore.sharedInstance.executeQuery(indexQuery)
    }
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
    }
    
}
