//
//  GalleryDelegate.swift
//  ImageViewer
//
// Created by David Whetstone on 1/5/17.
// Copyright (c) 2017 MailOnline. All rights reserved.
//

import Foundation

protocol GalleryItemsDelegate: class {
    func removeGalleryItem(at index: Int, onRemoved: @escaping () -> Void)
    func provideImageEntity(at index: Int) -> ImageEntity
}
