//
//  ImafeGalleryDocument.swift
//  ImageGallery
//
//  Created by Apple User on 26.05.2020.
//  Copyright © 2020 Alena Khoroshilova. All rights reserved.
//

import UIKit

class ImageGalleryDocument: UIDocument {
    
    var imageGallery: ImageGalleryDoc?
    
    override func contents(forType typeName: String) throws -> Any {
        return imageGallery?.json ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let json = contents as? Data {
            imageGallery = ImageGalleryDoc(json: json)
        }
    }
}

