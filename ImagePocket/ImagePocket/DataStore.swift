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
    
    static let sharedInstance = DataStore()
    private let connection: Connection?
    
    private init(){
        let fileName = "TinyNoteImagePocket.sqlite"
        
        let dirs = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true) as [NSString]
        
        let path = dirs[0].appendingPathComponent(fileName)
        print(path)
        
        do {
            connection = try Connection(path)
        } catch _ {
            connection = nil
        }
    }
    
    func executeQuery(_ query: String) throws {
        guard let connection = self.connection else {
            throw DataAccessError.connectionError
        }
       try connection.run(query)
    }
    
    func create() throws {
        try TagRepository.createTable()
        try ImageRepository.createTable()
    }
}
