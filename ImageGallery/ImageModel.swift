//
//  ImageGallery.swift
//  ImageGallery
//
//  Created by Apple User on 30.04.2020.
//  Copyright © 2020 Alena Khoroshilova. All rights reserved.
//

import Foundation

struct ImageModel: Codable {
    var url: URL
    var ascpectRatio: Double
}

class ImageGalleryModel {
    var name: String
    var images = [ImageModel]()
    
    init(withName name: String) {
        self.name = name
    }
    
    init(name: String, images: [ImageModel]) {
        self.name = name
        self.images = images
    }
}

struct ImageGalleryDoc: Codable {
    
    var images = [ImageModel]()
    
    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(ImageGalleryDoc.self, from: json) {
            self = newValue
        } else {
            return nil
        }
    }
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init(images: [ImageModel]) {
        self.images = images
    }
}
