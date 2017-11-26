//
//  SearchCache.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/1/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

final class SearchCache {
    private let _searchRepository = SearchRepository.instance
    
    static let instance = SearchCache()
    
    private init() {
    }
    
    // TODO Check on duplicates
    public func search(_ terms: [String]) -> [SearchResultEntity] {
        return _searchRepository.search(terms)
    }
}
