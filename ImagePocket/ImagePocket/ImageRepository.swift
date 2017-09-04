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
    private let _tagImageTable = Table("TagImage")
    
    public static let instance = ImageRepository()
    
    func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.localIdentifier)
            t.column(Columns.creationDate)
        }
        
        let indexQuery = _table.createIndex([Columns.localIdentifier], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    func createTagImageTable() throws {
        
        let tableQuery = _tagImageTable.create(ifNotExists: true) { t in
            t.column(TagImageColumns.id, primaryKey: true)
            t.column(TagImageColumns.imageId)
            t.column(TagImageColumns.tagId)
        }
        
        let indexQuery = _tagImageTable.createIndex([TagImageColumns.imageId], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }

    
    func getAll() -> [ImageEntity] {
        
        var result = [Int64: ImageEntity]()
        
        let table =  _table.select(_table[Columns.localIdentifier], _table[Columns.creationDate],
                                   _tagImageTable[TagImageColumns.imageId], _tagImageTable[TagImageColumns.tagId], _tagImageTable[TagImageColumns.id])
                            .join(_tagImageTable, on: TagImageColumns.imageId == _table[Columns.id])
        
        if let rows = try? DataStore.instance.db.prepare(table){
            rows.forEach{ row in
                
                let tagImage = TagImageEntity(id: row[TagImageColumns.id], tagId: row[TagImageColumns.tagId])
                
                if let item = result[row[TagImageColumns.imageId]] {
                    item.appendTagId(entity: tagImage)
                }
                else {
                    let item = ImageEntity(id: row[TagImageColumns.imageId], localIdentifier: row[Columns.localIdentifier], creationDate: row[Columns.creationDate])
                    item.appendTagId(entity: tagImage)
                    result[item.id] = item
                }
            }
        }
        
        return result.values.toArray()
    }
    
    func addTagImage(imageId: Int64, entities: [TagEntity]) -> [TagImageEntity] {
        if entities.isEmpty {
            return []
        }
        var result = [TagImageEntity]()
        for item in entities {
            let query = _tagImageTable.insert(TagImageColumns.imageId <- imageId, TagImageColumns.tagId <- item.id)
            if let id = try? DataStore.instance.db.run(query){
                result.append(TagImageEntity(id: id, tagId: item.id))
            }
        }
        return result
    }
    
    func remove(tagImages: [TagImageEntity]) -> Void {
        if tagImages.isEmpty {
            return
        }
        _ = _tagImageTable.filter(tagImages.map {$0.id}.contains(Columns.id)).delete()
    }
    
    func remove(_ entities: [ImageEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        _ = _table.filter(entities.map {$0.id}.contains(Columns.id)).delete()
    }
    
    func saveOrUpdate(_ entities: [ImageEntity]) -> Void {
        if entities.isEmpty {
            return
        }
        
        let forRemove = entities.filter{ x in
            x.isNew == false && x.hasTags == false
        }
        let forAddOrUpdate = entities.filter { $0.hasTags }
        
        remove(forRemove)
        addOrUpdate(forAddOrUpdate)
    }
    
    private func addOrUpdate(_ entities: [ImageEntity]) -> Void {
        
        if entities.isEmpty {
            return
        }
        
        entities.forEach{ entity in
            if entity.isNew {
                let query = _table.insert(Columns.localIdentifier <- entity.localIdentifier, Columns.creationDate <- entity.creationDate)
                if let id  = try? DataStore.instance.db.run(query){
                    entity.id = id
                }
            }
        }
    }
    
    
    private struct Columns {
        static let id = Expression<Int64>("id")
        static let localIdentifier = Expression<String>("localIdentifier")
        static let creationDate = Expression<Date?>("creationDate")
    }
    
    private struct TagImageColumns {
        static let id = Expression<Int64>("id")
        static let imageId = Expression<Int64>("imageId")
        static let tagId = Expression<Int64>("tagId")
    }
}
