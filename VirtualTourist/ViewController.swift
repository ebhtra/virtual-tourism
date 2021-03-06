//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Ethan Haley on 11/18/15.
//  Copyright © 2015 Ethan Haley. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    @IBOutlet weak var globalMap: MKMapView!
    
    @IBOutlet weak var deletePinLabel: UILabel!
    
    var longPress = UILongPressGestureRecognizer() //for dropping pins
    var newPin: Pin? //holds each new pin until user lifts finger
    var annotationList = [Pin]()
    var isEditingPins = false
    var editButton = UIBarButtonItem()
    
    lazy var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lat", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set map to last region and zoom
        restoreMapRegion(true)
        
        globalMap.delegate = self
        
        longPress.minimumPressDuration = 0.25
        longPress.addTarget(self, action: #selector(ViewController.placePin(_:)))
        view.addGestureRecognizer(longPress)
        
        editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(ViewController.selectEditMode(_:)))
        navigationItem.rightBarButtonItem = editButton
        
        deletePinLabel.isHidden = true
        
        //get and display all stored Pins
        do {
            try fetchedResultsController.performFetch()
            annotationList = fetchedResultsController.fetchedObjects as! [Pin]
            globalMap.addAnnotations(annotationList)
        } catch {
            print(error)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //keep current region and zoom level
        saveMapRegion()
    }
    
    func placePin(_ recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .began: dropPin(recognizer.location(in: globalMap))
        case .changed: updatePinLoc(recognizer.location(in: globalMap))
        case .ended: storePin()
        default: break
        }
    }
    /*       FOR PURPLE PINS:
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = UIColor.purpleColor()
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    */
    func dropPin(_ atPoint: CGPoint) {
        //after long touch, create new Pin object and store it in Context
        let geoPoint = globalMap.convert(atPoint, toCoordinateFrom: globalMap)
        newPin = Pin(lat: geoPoint.latitude, lon: geoPoint.longitude, context: sharedContext)
        globalMap.addAnnotation(newPin!)
    }
    
    func updatePinLoc(_ toPoint: CGPoint) {
        //during dragging, update new Pin's location
        let geoPoint = globalMap.convert(toPoint, toCoordinateFrom: globalMap)
        newPin!.setCoordinate(geoPoint)
    }

    func storePin() {
        //after touch up, store final Pin location, and initiate photo download
        CoreDataStackManager.sharedInstance().saveContext()
        FlickrClient.sharedInstance.getFlickrPicsFromPin(newPin!)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let spot = view.annotation as! Pin
        //unless editing (removing) pins, segue to photo display scene for the tapped pin
        if !isEditingPins {
            // first center the map on the selected pin for user's reference upon return
            globalMap.centerCoordinate = spot.coordinate
            let nextVC = storyboard!.instantiateViewController(withIdentifier: "PhotoAlbum") as! PhotoCollectionVC
            nextVC.site = spot
            mapView.deselectAnnotation(spot, animated: false)
            navigationController!.pushViewController(nextVC, animated: true)
        } else {
            globalMap.removeAnnotation(spot)
            sharedContext.delete(spot)
            //persist the deletion of the managed object
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
    }
    func selectEditMode(_ button: UIBarButtonItem) {
        //toggle editing state and update view accordingly
        if isEditingPins {
            editButton.title = "Edit"
            isEditingPins = false
            self.view.frame.origin.y = 0
            deletePinLabel.isHidden = true
        } else {
            editButton.title = "Done"
            isEditingPins = true
            self.view.frame.origin.y -= deletePinLabel.frame.height
            deletePinLabel.isHidden = false
        }
    }
    
    // MARK: -- Setting and saving the UI state
    //
    // This code is copied from Udacity's MemoryMap app in the ios-persistence course
    
    var filePath : String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first
        return url!.appendingPathComponent("mapRegionArchive").path
    }
    
    func saveMapRegion() {
        
        // Place the "center" and "span" of the map into a dictionary
        // The "span" is the width and height of the map in degrees.
        // It represents the zoom level of the map.
        
        let dictionary = [
            "latitude" : globalMap.region.center.latitude,
            "longitude" : globalMap.region.center.longitude,
            "latitudeDelta" : globalMap.region.span.latitudeDelta,
            "longitudeDelta" : globalMap.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(_ animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            globalMap.setRegion(savedRegion, animated: animated)
        }
    }

    
}

