//
//  SearchCache.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/1/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

final class SearchCache {
    
    private let SearchCacheInitialized = "SearchCacheInitialized"
    
    static let instance = SearchCache()
    
    public func fill() -> Void {
        if UserDefaults.standard.bool(forKey: SearchCacheInitialized) {
            return
        }
    }
}
