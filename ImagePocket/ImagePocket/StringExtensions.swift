//
//  StringExtensions.swift
//  ImagePocket
//
//  Created by Serjo on 22/10/16.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation

public extension String {
    
    static var empty: String {
        return ""
    }
    
    func isEmpty() -> Bool {
        return self == ""
    }
}
