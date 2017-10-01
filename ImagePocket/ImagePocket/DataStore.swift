//
//  DataStore.swift
//  ImagePocket
//
//  Created by Serjo on 22/10/16.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation
import SQLite

final class DataStore {
    
    static let instance = DataStore()
    public let db: Connection!
    
    private init(){
        let fileName = "TinyNoteImagePocket.sqlite"
        
        let dirs = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true) as [NSString]
        
        let path = dirs[0].appendingPathComponent(fileName)
        print(path)
        
        db = try! Connection(path)

    }
    
    func create() throws {
        try TagRepository.instance.createTable()
        try ImageRepository.instance.createTable()
        try ImageRepository.instance.createTagImageTable()
        try SearchRepository.instance.createTable()
    }
}
