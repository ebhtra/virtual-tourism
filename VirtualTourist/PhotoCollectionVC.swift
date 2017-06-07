//
//  PhotoCollectionVC.swift
//  VirtualTourist
//
//  Created by Ethan Haley on 11/28/15.
//  Copyright © 2015 Ethan Haley. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoCollectionVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var mapDisplay: MKMapView!
    @IBOutlet weak var noPicsLabel: UILabel!
    
    let placeholder = UIImage(named: "hourglassIcon")
    
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext

    var site: Pin!
    
    // A staging area for indices of Photos before they are deleted
    var selectedIndexes = [IndexPath]()
    
    // A staging area for indices of Photos before the batch update
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Deal with the zero-pic situation
        if site.pics.isEmpty {
            noPicsLabel.isHidden = false
            bottomButton.isEnabled = false
        }
        // Place the current pin on the small map above the Photo collection
        mapDisplay.addAnnotation(site)
        mapDisplay.setRegion(MKCoordinateRegion(center: site.coordinate, span: MKCoordinateSpanMake(0.2, 0.5)), animated: true)
        
        fetchedResultsController.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        do {  // get the currently persisted Photos for this Pin
            try fetchedResultsController.performFetch()
        } catch {
            print(error)
        }
    }
    // This controller will control Photos in this managed Context whose related Pin is the current one
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        //get the photos whose related Pin matches this one
        fetchRequest.predicate = NSPredicate(format: "site == %@", self.site)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        return fetchedResultsController
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        // Lay out the collection view so that cells are squares 1/2 the width of the View
        let width = collectionView.frame.size.width/2
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
    }

    @IBAction func bottomButtonClicked(_ sender: AnyObject) {
        //either add photos to the for-deletion list or replace them all with a new call to flickr
        if selectedIndexes.isEmpty {
            replaceAllPhotos()
        } else {
            deleteSelectedPhotos()
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    // MARK: - UICollectionView DataSource and Delegate methods
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PicCell", for: indexPath) as! PhotoCell
        let picture = self.fetchedResultsController.object(at: indexPath) as! Photo
        if let _ = selectedIndexes.index(of: indexPath) {
            selectPic(cell)
        } else {
            deselectPic(cell)
        }
        //If the Photo object for the cell already has a UIImage stored, use it,
        //  otherwise show a placeholder while getting the image from the stored URL
        if picture.image != nil {
            cell.pic.image = picture.image
        } else {
            cell.pic.image = placeholder
            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            cell.addSubview(activityIndicator)
            activityIndicator.color = UIColor.yellow
            activityIndicator.frame = cell.bounds
            activityIndicator.startAnimating()
            
            let _ = taskForImage(picture.imageURL) { data, error in
                if let _ = error{
                    // show the error photo
                    picture.image = UIImage(named: "image-2")
                } else {
                    let image = UIImage(data: data!)
                    //need main queue for core data thread safety
                    DispatchQueue.main.async {
                        picture.image = image
                        cell.pic.image = image
                        activityIndicator.removeFromSuperview()
                    }
                }
            }
        }
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath) as! PhotoCell
        
        // When a cell is tapped this method will toggle its presence in the selectedIndexes array.
        // Also it will toggle its alpha accordingly.
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
            deselectPic(cell)
        } else {
            selectedIndexes.append(indexPath)
            selectPic(cell)
        }

        updateBottomButton()
        
    }
    // helper func to toggle a cell's appearance
    func selectPic(_ pic: PhotoCell) {
        pic.pic.alpha = 0.33
        pic.backgroundColor = UIColor.yellow
        
    }
    // helper func to toggle a cell's appearance
    func deselectPic(_ pic: PhotoCell) {
        pic.pic.alpha = 1.0
        pic.backgroundColor = UIColor.black
    }
    // helper func to toggle the bottom button
    func updateBottomButton() {
        if selectedIndexes.isEmpty {
            bottomButton.title = "Get New Photos"
        } else {
            bottomButton.title = "Delete Selected Photos"
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    /* Most of this is taken from the "ColorCollection" app in the Udacity ios-persistence course */
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()

    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // It will store index paths into the three arrays.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type{
            
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            updatedIndexPaths.append(indexPath!)
            break
        default: break
        }
    }
    
    // This method is invoked after all of the changes in the current batch have been collected
    // into the three index path arrays (insert, delete, and update). We now need to loop through the
    // arrays and perform the changes.
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
           
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            }, completion: nil)
    }
    
    func replaceAllPhotos() {
        //Delete all the currently displayed Photos and replace them with new ones from flickr
        for pic in fetchedResultsController.fetchedObjects as! [Photo] {
            pic.image = nil
            sharedContext.delete(pic)
        }
        CoreDataStackManager.sharedInstance().saveContext()
        
        FlickrClient.sharedInstance.getFlickrPicsFromPin(site)
    }
    
    func deleteSelectedPhotos() {
        var picsToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            picsToDelete.append(fetchedResultsController.object(at: indexPath) as! Photo)
        }
        
        for pic in picsToDelete {
            pic.image = nil 
            sharedContext.delete(pic)
        }
        
        selectedIndexes = [IndexPath]()
        //if all pics were deleted, enable getting more
        if site.pics.isEmpty {
            bottomButton.isEnabled = true
        }
        //toggle bottom button back to "replace all" state
        updateBottomButton()
    }
    
    // data task for making UIImages from stored URL's
    func taskForImage(_ filePath: String, completionHandler: @escaping (_ imageData: Data?, _ error: NSError?) ->  Void) -> URLSessionTask {
    
        let request = URLRequest(url: URL(string: filePath)!)
        let task = URLSession.shared.dataTask(with: request, completionHandler: {data, response, downloadError in
            
            if let error = downloadError {
                print(error.localizedDescription)
                completionHandler(nil, error as NSError?)
            }  else {
                completionHandler(data, nil)
            }
        }) 
        
        task.resume()
        
        return task
    }
    
}
