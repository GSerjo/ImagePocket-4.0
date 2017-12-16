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
    
    private init(){
    }
    
    public func createTable() throws {
        
        let tableQuery = _table.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.localIdentifier)
            t.column(Columns.creationDate)
        }
        
        let indexQuery = _table.createIndex([Columns.localIdentifier], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }
    
    public func createTagImageTable() throws {
        
        let tableQuery = _tagImageTable.create(ifNotExists: true) { t in
            t.column(TagImageColumns.id, primaryKey: true)
            t.column(TagImageColumns.imageId)
            t.column(TagImageColumns.tagId)
        }
        
        let indexQuery = _tagImageTable.createIndex([TagImageColumns.imageId], ifNotExists: true)
        
        try DataStore.instance.db.run(tableQuery)
        try DataStore.instance.db.run(indexQuery)
    }

    
    public func getAll() -> [ImageEntity] {
        
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
    
    public func getBy(ids: [Int64]) -> [ImageEntity] {
        var result = [ImageEntity]()
        _ = try? DataStore.instance.db.transaction {[unowned self] in
            let query = self._table.filter(ids.contains(Columns.id))
            if let rows = try? DataStore.instance.db.prepare(query) {
                for row in rows {
                    let item = ImageEntity(id: row[Columns.id], localIdentifier: row[Columns.localIdentifier], creationDate: row[Columns.creationDate])
                    result.append(item)
                }
            }
        }
        return result
    }
    
    public func addTagImage(imageId: Int64, entities: [TagEntity]) -> [TagImageEntity] {
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
    
    public func remove(tagImages: [TagImageEntity]) -> Void {
        if tagImages.isEmpty {
            return
        }
        let query = _tagImageTable.filter(tagImages.map {$0.id}.contains(Columns.id)).delete()
        _  = try? DataStore.instance.db.run(query)
    }
    
    public func remove(tags: [TagEntity]) -> [TagImageEntity] {
        if tags.isEmpty {
            return []
        }
        var removed = [TagImageEntity]()
        _ = try? DataStore.instance.db.transaction {[unowned self] in
            let query = self._tagImageTable.filter(tags.map{$0.id}.contains(TagImageColumns.tagId))
            if let rows = try? DataStore.instance.db.prepare(query) {
                for row in rows {
                    let entity = TagImageEntity(id: row[TagImageColumns.id], tagId: row[TagImageColumns.tagId], imageId: row[TagImageColumns.imageId])
                    removed.append(entity)
                }
            }
            self.remove(tagImages: removed)
        }
        return removed
    }
    
    public func saveOrUpdate(_ entities: [ImageEntity]) -> (remove: [ImageEntity], add: [ImageEntity]) {
        if entities.isEmpty {
            return ([], [])
        }
        
        let forRemove = entities.filter{ $0.isNew == false && $0.hasTags == false }
        let forAdd = entities.filter { $0.isNew && $0.hasTags }
        
        _ = try? DataStore.instance.db.transaction {[unowned self] in
            
            if forRemove.isEmpty == false {
                let query = self._table.filter(forRemove.map {$0.id}.contains(Columns.id)).delete()
                _  = try? DataStore.instance.db.run(query)
            }
            
            
            if forAdd.isEmpty == false {
                for entity in forAdd {
                    if entity.isNew {
                        let query = self._table.insert(
                            Columns.localIdentifier <- entity.localIdentifier,
                            Columns.creationDate <- entity.creationDate)
                        
                        if let id  = try? DataStore.instance.db.run(query){
                            entity.id = id
                        }
                    }
                }
            }
        }
        return (forRemove, forAdd)
    }
    
    public func remove(localIdentifiers: [String]) -> Void {
        if localIdentifiers.isEmpty {
            return
        }
        let query = _table.select(Columns.id).filter(localIdentifiers.contains(Columns.localIdentifier))
        _ = try? DataStore.instance.db.transaction {[unowned self] in
            
            var forRemove = [Int64]()
            if let rows = try? DataStore.instance.db.prepare(query) {
                for row in rows {
                    forRemove.append(row[Columns.id])
                }
            }
            if forRemove.isEmpty == false {
                let removeImages = self._table.filter(forRemove.contains(Columns.id)).delete()
                _  = try? DataStore.instance.db.run(removeImages)
                
                let removeTagImages = self._tagImageTable.filter(forRemove.contains(TagImageColumns.imageId)).delete()
                _  = try? DataStore.instance.db.run(removeTagImages)
            }
        }
        SearchRepository.instance.remove(localIdentifiers)
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
