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
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
    }
    
}
