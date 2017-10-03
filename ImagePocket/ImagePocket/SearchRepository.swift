//
//  SearchRepository.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/1/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import SQLite

final class SearchRepository {
    
    private let _table = VirtualTable("search")
    
    public static let instance = SearchRepository()
    
    func createTable() throws -> Void {
        let config = FTS5Config()
            .column(Columns.text)
            .column(Columns.localIdentifier)
        
        let tableQuery = _table.create(.FTS5(config), ifNotExists: true)
        try DataStore.instance.db.run(tableQuery)
    }
    
    func save(entity: SearchEntity) -> Void {
        let query = _table.insert(Columns.localIdentifier <- entity.localIdentifier, Columns.text <- entity.text)
        let _ = try? DataStore.instance.db.run(query)
    }
    
    func remove(_ entityIds: [String]) -> Void {
        if entityIds.isEmpty {
            return
        }
        
        for id in entityIds {
            let _ = _table.filter(Columns.localIdentifier.match(id)).delete()
        }
    }
    
    func search(text: String) -> [SearchResultEntity] {
        var result = [SearchResultEntity]()
        
        let table = _table.filter(Columns.text.match(text))
        if let rows = try? DataStore.instance.db.prepare(table){
            rows.forEach{row in
                result.append(SearchResultEntity(localIdentifier: row[Columns.localIdentifier]))
            }
        }
        
        return result
    }
    
    private struct Columns {
        static let text = Expression<String>("text")
        static let localIdentifier = Expression<String>("localIdentifier")
    }
}
