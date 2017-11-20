//
//  SearchCache.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/1/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation
import Photos

final class SearchCache {
    private let _searchRepository = SearchRepository.instance
    private let _geoHashAssetRepository = GeoAssetRepository.instance
    private let _geoHashRepository = GeoHashRepository.instance
    private let _dateFormatter = DateFormatter()
    
    static let instance = SearchCache()
    
    private init() {
        _dateFormatter.dateFormat = "yyyy LLLL"
    }
    
    public func search(_ terms: [String]) -> [SearchResultEntity] {
        return _searchRepository.search(terms)
    }
}
