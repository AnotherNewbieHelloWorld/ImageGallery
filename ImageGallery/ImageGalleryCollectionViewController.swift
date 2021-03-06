//
//  ImageGalleryCollectionViewController.swift
//  ImageGallery
//
//  Created by Apple User on 22.04.2020.
//  Copyright © 2020 Alena Khoroshilova. All rights reserved.
//

import UIKit

private let reuseIdentifier = "ImageCell"

class ImageGalleryCollectionViewController: UICollectionViewController, UICollectionViewDropDelegate,UICollectionViewDragDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: - Model
    
    var imageGallery: ImageGalleryDoc? {
        get {
            return ImageGalleryDoc(images: imageGalleryModel.images)
        }
        set {
            imageGalleryModel = ImageGalleryModel(name: "", images: [])
            collectionView.reloadData()
            /** Fetch image **/
            if let images = newValue?.images {
                imageGalleryModel.images = images
            }
            collectionView.reloadData()
        }
    }
    
    var document: ImageGalleryDocument?
    
    var firstImage: UIImageView? {
        return (self.collectionView!.cellForItem(at: IndexPath(row: 0, section: 0)) as? ImageGalleryCollectionViewCell)?.imageForCell
    }
    
    func documentChanged() {
        /** Autosave! Not Save Button **/
        document?.imageGallery = imageGallery
        if document?.imageGallery != nil {
            document?.updateChangeCount(.done)
        }
    }
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        documentChanged()
        if document?.imageGallery != nil {
            if let firstImage = firstImage?.snapshot {
                document?.thumbnail = firstImage
            }
        }
        dismiss(animated: true) {
            self.document?.close()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        document?.open(completionHandler: { success in
            if success {
                self.title = self.document?.localizedName
                self.imageGallery = self.document?.imageGallery
            }
        })
    }
    
    // MARK: - Storyboard
    
    var imageGalleryModel = ImageGalleryModel(withName: "🌈")
        
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
        collectionView.dragInteractionEnabled = true
        collectionView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(ImageGalleryCollectionViewController.zoom(_:))))
        
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        flowLayout?.invalidateLayout()
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageGalleryModel.images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        if let imageCell = cell as? ImageGalleryCollectionViewCell {
            imageCell.changeAspectRatio = { [weak self] in
//                if let aspectRatio = self?.images[indexPath.item].ascpectRatio, aspectRatio < 0.95 || aspectRatio > 1.05 {
//                    self?.images[indexPath.item].ascpectRatio = 1.0
                    self?.flowLayout?.invalidateLayout()
//                }
            }
            imageCell.imageURL = imageGalleryModel.images[indexPath.item].url
        }
        return cell
    }
    
    @objc func zoom(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            scale *= gesture.scale
            gesture.scale = 1.0
        }
    }
    
    var flowLayout: UICollectionViewFlowLayout? {
        return collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    struct Constants {
        static let columnCount = 3.0
        static let minWidthRatio = CGFloat(0.03)
    }
    
    var boundsCollectionWidth: CGFloat {
        return (collectionView?.bounds.width)!
    }
    
    var gapItems: CGFloat {
        return (flowLayout?.minimumInteritemSpacing)! * CGFloat((Constants.columnCount - 1.0))
    }
    
    var gapSections: CGFloat {
        return (flowLayout?.sectionInset.right)! * 2.0
    }
    
    var scale: CGFloat = 1  {
        didSet {
            collectionView?.collectionViewLayout.invalidateLayout()
        }
    }
    
    var predefinedWidth: CGFloat {
        let width = floor((boundsCollectionWidth - gapItems - gapSections) / CGFloat(Constants.columnCount)) * scale
        return  min(max(width, boundsCollectionWidth * Constants.minWidthRatio), boundsCollectionWidth)}
    
    
    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = predefinedWidth
        let aspectRatio = CGFloat(imageGalleryModel.images[indexPath.item].ascpectRatio)
        return CGSize(width: width, height: width/aspectRatio)
    }
    
    
    // MARK: - Image Fetcher && Drag and Drop
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if let imageCell = collectionView.cellForItem(at: indexPath) as? ImageGalleryCollectionViewCell,
            let image = imageCell.imageForCell.image {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
            dragItem.localObject = imageGalleryModel.images[indexPath.item]
            return [dragItem]
        } else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
/// 1
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        if isSelf {
            return session.canLoadObjects(ofClass: UIImage.self)
        } else {
            return session.canLoadObjects(ofClass: NSURL.self) &&
            session.canLoadObjects(ofClass: UIImage.self)
        }
    }
    
/// 2
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    /// 3
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                // do the local case
                if let image = item.dragItem.localObject as? ImageModel {
                    collectionView.performBatchUpdates({
                         imageGalleryModel.images.remove(at: sourceIndexPath.item)
                         imageGalleryModel.images.insert(image, at: destinationIndexPath.item)
                        
                         collectionView.deleteItems(at: [sourceIndexPath])
                         collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                    self.documentChanged()
                }
            } else {
                // handle the drop from the other app
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                
                var optionalImageURL: URL?
                var optionalAspectRatio: Double?
                
                // load image
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            optionalAspectRatio = Double(image.size.width)/Double(image.size.height)
                        }
                    }
                }
                
                // load url 
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { (nsurl, error) in
                    DispatchQueue.main.async {
                        if let url = nsurl as? URL {
                            optionalImageURL = url.imageURL
                        }
                        if optionalImageURL != nil, optionalAspectRatio != nil{
                            
                            placeholderContext.commitInsertion(dataSourceUpdates: {
                                insertionIndexPath in
                                self.imageGalleryModel.images.insert(ImageModel(url: optionalImageURL!, ascpectRatio: optionalAspectRatio!), at: insertionIndexPath.item)
                            })
                            self.documentChanged()
                        } else {
                            print(error?.localizedDescription ?? "Error")
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation
    
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        performSegue(withIdentifier: "Show Image", sender: indexPath)
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "Show Image":
                if let cell = sender as? ImageGalleryCollectionViewCell,
                    let indexPath = collectionView.indexPath(for: cell),
                    let seguedToMVC = segue.destination as? ImageViewController {
                    seguedToMVC.imageURL = imageGalleryModel.images[indexPath.item].url
                }
            default:
                break
            }
        }
    }
}
