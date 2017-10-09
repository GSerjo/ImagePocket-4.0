//
//  Settings.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/8/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

final class Settings {
    
    private let _tagKey = "TagKey"
    private let _tagCache = TagCache.instance
    
    static let instance = Settings()
    
    private init(){
    }
    
    func save(_ tag: TagEntity) -> Void {
        UserDefaults.standard.set(tag.id, forKey: _tagKey)
    }
    
    func getTag() -> TagEntity {
        if containsKey(key: _tagKey) {
            let id = UserDefaults.standard.integer(forKey: _tagKey)
            if let entity = TagCache.instance.getById(tagId: Int64(id)){
                return entity
            }
            return TagEntity.all
        }
        return TagEntity.all
    }
    
    private func containsKey(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}
