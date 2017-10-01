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
            .column(Columns.localIdentifier, [.unindexed])
        
        try DataStore.instance.db.run(_table.create(.FTS5(config)))
    }
    
    func search(text: String) -> [String] {
        
    }
    
    private struct Columns {
        static let text = Expression<Int64>("text")
        static let localIdentifier = Expression<String>("localIdentifier")
    }
}
