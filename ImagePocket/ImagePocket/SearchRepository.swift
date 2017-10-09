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
        let config = FTS4Config()
            .column(Columns.text)
            .column(Columns.localIdentifier)
        
        let tableQuery = _table.create(.FTS4(config), ifNotExists: true)
        try DataStore.instance.db.run(tableQuery)
    }
    
    func save(entity: SearchEntity) -> Void {
        if entity.text.isEmpty() {
            return
        }
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
        let searchText = createSearchText(text)
        let table = _table.filter(Columns.text.match("\(searchText)"))
        if let rows = try? DataStore.instance.db.prepare(table){
            rows.forEach{row in
                result.append(SearchResultEntity(localIdentifier: row[Columns.localIdentifier]))
            }
        }
        return result
    }
    
    private func createSearchText(_ text: String) -> String {
        var result = String.empty
        let components = text.components(separatedBy: " ").map{$0.trimmingCharacters(in: .whitespacesAndNewlines)}.filter{!$0.isEmpty()}
        if components.count > 1 {
            for (index, item) in components.enumerated() {
                if index == 0 {
                    result = "\(item)* AND "
                    continue
                }
                if index != components.count - 1 {
                    result = "\(result)\(item)* AND "
                } else {
                    result = "\(result)\(item)*"
                }
            }
        } else {
            result = "\(text.trimmingCharacters(in: .whitespacesAndNewlines))*"
        }
        return result
    }
    
    private struct Columns {
        static let text = Expression<String>("text")
        static let localIdentifier = Expression<String>("localIdentifier")
    }
}
