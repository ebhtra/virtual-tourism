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
    
    var longPress = UILongPressGestureRecognizer()
    var newPin: Pin?
    var annotationList = [Pin]()
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lat", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        globalMap.delegate = self
        longPress.minimumPressDuration = 0.25
        longPress.addTarget(self, action: Selector("placePin:"))
        view.addGestureRecognizer(longPress)

        do {
            try fetchedResultsController.performFetch()
            annotationList = fetchedResultsController.fetchedObjects as! [Pin]
            globalMap.addAnnotations(annotationList)
        } catch {
            print(error)
        }
            }
    
    func placePin(recognizer: UIGestureRecognizer) {
        switch recognizer.state {
        case .Began: dropPin(recognizer.locationInView(globalMap))
        case .Changed: updatePinLoc(recognizer.locationInView(globalMap))
        case .Ended: storePin()
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
    func dropPin(atPoint: CGPoint) {
        let geoPoint = globalMap.convertPoint(atPoint, toCoordinateFromView: globalMap)
        newPin = Pin(lat: geoPoint.latitude, lon: geoPoint.longitude, context: sharedContext)
        globalMap.addAnnotation(newPin!)
    }
    
    func updatePinLoc(toPoint: CGPoint) {
        let geoPoint = globalMap.convertPoint(toPoint, toCoordinateFromView: globalMap)
        newPin!.setCoordinate(geoPoint)
    }

    func storePin() {
        CoreDataStackManager.sharedInstance().saveContext()
        FlickrClient.sharedInstance.getFlickrPicsFromPin(newPin!)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let spot = view.annotation as! Pin
        let nextVC = storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoCollectionVC
        nextVC.site = spot
        // set the mapview above the nextVC controller view now too
        navigationController!.pushViewController(nextVC, animated: true)
        
    }
    
        


}

