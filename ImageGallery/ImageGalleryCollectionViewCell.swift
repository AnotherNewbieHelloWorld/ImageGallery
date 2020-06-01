//
//  ImageGalleryCollectionViewCell.swift
//  ImageGallery
//
//  Created by Apple User on 22.04.2020.
//  Copyright © 2020 Alena Khoroshilova. All rights reserved.
//

import UIKit

class ImageGalleryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageForCell: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var imageURL: URL? {
        didSet { updateUI() }
    }
    
    var changeAspectRatio: (() -> Void)?
    
    private func updateUI() {
        guard let url = imageURL, url == imageURL else { return }
        imageForCell.image = nil
        spinner.startAnimating()
        imageForCell.loadImage(fromURL: url) { [weak self] in
            self?.spinner.stopAnimating()
        }
    }
    
/**      if let url = imageURL {
            imageForCell.image = nil
            spinner.startAnimating()

            DispatchQueue.global(qos: .userInitiated).async {
                let data = try? Data(contentsOf: url)

                DispatchQueue.main.async {
                    if let imData = data, url == self.imageURL, let image = UIImage(data: imData) {
                        self.spinner.stopAnimating()
                        self.imageForCell.image = image
                    }
                }
            }
        }
**/

}

extension UIImageView {
    
    public func loadImage(fromURL imageURL: URL, complitionHandler: (() -> Void)?) {
                
        let cache = URLCache.shared
        let request = URLRequest(url: imageURL)
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            if let data = cache.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.transition(toImage: image)
                    if complitionHandler != nil { complitionHandler!() }
                }
            } else {
                
                URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                    if let data = data, let response = response, ((response as? HTTPURLResponse)?.statusCode ?? 500) < 300, let image = UIImage(data: data) {
                        let cachedData = CachedURLResponse(response: response, data: data)
                        cache.storeCachedResponse(cachedData, for: request)
                        DispatchQueue.main.async {
                            self.transition(toImage: image)
                        }
                    }
                }.resume()
            }
        }
    }
    
    public func transition(toImage image: UIImage?) {
        UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve], animations: { self.image = image }, completion: nil)
    }
}
