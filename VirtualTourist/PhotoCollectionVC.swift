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
    var selectedIndexes = [NSIndexPath]()
    
    // A staging area for indices of Photos before the batch update
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("the pin has \(site.pics.count) photos")
        // Deal with the zero-pic situation
        if site.pics.isEmpty {
            noPicsLabel.hidden = false
            bottomButton.enabled = false
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
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
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

    @IBAction func bottomButtonClicked(sender: AnyObject) {
        //either add photos to the for-deletion list or replace them all with a new call to flickr
        if selectedIndexes.isEmpty {
            replaceAllPhotos()
        } else {
            deleteSelectedPhotos()
        }
    }
    
    // MARK: - UICollectionView DataSource and Delegate methods
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PicCell", forIndexPath: indexPath) as! PhotoCell
        let picture = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        if let _ = selectedIndexes.indexOf(indexPath) {
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
            dispatch_async(dispatch_get_main_queue()) {
                let nsurl = NSURL(string: picture.imageURL)
                let image = UIImage(data: NSData(contentsOfURL: nsurl!)!)
                picture.image = image
                cell.pic.image = image
            }
        }
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // When a cell is tapped this method will toggle its presence in the selectedIndexes array.
        // Also it will toggle its alpha accordingly.
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
            deselectPic(cell)
        } else {
            selectedIndexes.append(indexPath)
            selectPic(cell)
        }

        updateBottomButton()
        
    }
    func selectPic(pic: PhotoCell) {
        pic.pic.alpha = 0.33
        pic.backgroundColor = UIColor.yellowColor()
        
    }
    func deselectPic(pic: PhotoCell) {
        pic.pic.alpha = 1.0
        pic.backgroundColor = UIColor.blackColor()
    }
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
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()

    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // It will store index paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            updatedIndexPaths.append(indexPath!)
            break
        default: break
        }
    }
    
    // This method is invoked after all of the changes in the current batch have been collected
    // into the three index path arrays (insert, delete, and update). We now need to loop through the
    // arrays and perform the changes.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({() -> Void in
           
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    func replaceAllPhotos() {
        //Delete all the currently displayed Photos and replace them with new ones from flickr
        for pic in fetchedResultsController.fetchedObjects as! [Photo] {
            pic.image = nil
            sharedContext.deleteObject(pic)
        }
        FlickrClient.sharedInstance.getFlickrPicsFromPin(site)
    }
    
    func deleteSelectedPhotos() {
        var picsToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            picsToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for pic in picsToDelete {
            pic.image = nil 
            sharedContext.deleteObject(pic)
        }
        
        selectedIndexes = [NSIndexPath]()
        //toggle bottom button back to "replace all" state
        updateBottomButton()
    }
    
}
