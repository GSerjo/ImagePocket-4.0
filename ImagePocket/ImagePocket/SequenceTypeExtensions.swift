//
//  SequenceTypeExtensions.swift
//  ImagePocket
//
//  Created by Serjo on 22/10/16.
//  Copyright © 2016 Serjo. All rights reserved.
//

import Foundation

public extension Sequence {
    func toDictionary<Key: Hashable, Value>(fn: (Value) -> Key) -> [Key: Value] {
        var result = [Key: Value]();
        
        for x in self {
            let item = x as! Value
            result[fn(item)] = item
        }
        
        return result;
    }
}
