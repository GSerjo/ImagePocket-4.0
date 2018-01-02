//
//  Settings.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/8/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import UIKit

final class Settings {
    
    private let _tagCache = TagCache.instance
    private var _appStatus: AppStatus = .none
    
    static let instance = Settings()
    
    private init(){
        if containsKey(key: Key.AppStatus) {
            _appStatus = AppStatus(rawValue: UserDefaults.standard.integer(forKey: Key.AppStatus)) ?? .none
        }
    }
    
    var appStatus: AppStatus {
        get {
            return _appStatus
        }
        set(valueValue){
            UserDefaults.standard.set(valueValue.rawValue, forKey: Key.AppStatus)
            _appStatus = valueValue
        }
    }
    
    var theme: Theme {
        return Theme()
    }
    
    public func save(_ tag: TagEntity) -> Void {
        UserDefaults.standard.set(tag.id, forKey: Key.Tag)
    }
    
    public func getTag() -> TagEntity {
        if containsKey(key: Key.Tag) {
            let id = UserDefaults.standard.integer(forKey: Key.Tag)
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
    
    private struct Key {
        static let Tag = "TagKey"
        static let AppStatus = "AppStatus"
        
        private init(){
        }
    }
    
    struct Theme {
//        let barTintColor = #colorLiteral(red: 0.199973762, green: 0.2000150383, blue: 0.1999712288, alpha: 1)
        let barTintColor = #colorLiteral(red: 0.1633343031, green: 0.1029568759, blue: 0.1803530857, alpha: 1)
        let tintColor = #colorLiteral(red: 0.5671468377, green: 0.6942085624, blue: 0.8048953414, alpha: 1)
        let titleTextColor = #colorLiteral(red: 0.9998915792, green: 1, blue: 0.9998809695, alpha: 1)
        let newTagTextColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
    }
}


