//
//  NotifiableOnTapProtocol.swift
//  ImagePocket
//
//  Created by Sergey Morenko on 9/6/17.
//  Copyright © 2017 Serjo. All rights reserved.
//

import Foundation

protocol NotifiableOnTapProtocol {
    func notifyOnTap()
    var isFullScreen: Bool { get }
}
