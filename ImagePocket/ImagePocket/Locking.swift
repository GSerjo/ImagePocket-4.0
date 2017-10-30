//
//  Locking.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 10/29/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

public func lock(_ lockable: NSLocking, criticalSection: () -> Void) {
    lockable.lock()
    criticalSection()
    lockable.unlock()
}
