//
//  SearchEntity.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/1/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

struct SearchEntity {
    public let text: String
    public let localIdentifier: String
    
    init?(_ items: [String], _ localIdentifier: String){
        if items.isEmpty {
            return nil
        }
        text = items.joined(separator: " ")
        self.localIdentifier = localIdentifier
    }
    
    init(text: String, localIdentifier: String) {
        self.text = text
        self.localIdentifier = localIdentifier
    }
}
