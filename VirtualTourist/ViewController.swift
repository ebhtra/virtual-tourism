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
    var currentPin: TemporaryPin?
    var annotationList = [Pin]()
    var tempPinsList = [TemporaryPin]()
    
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
            currentPin = TemporaryPin()
            for point in annotationList {
                let newPin = TemporaryPin()
                newPin.setCoordinate(CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon))
                tempPinsList.append(newPin)
            }
            globalMap.addAnnotations(tempPinsList)
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
    /*
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
        currentPin = TemporaryPin()
        currentPin!.setCoordinate(geoPoint)
        globalMap.addAnnotation(currentPin!)
    }
    
    func updatePinLoc(toPoint: CGPoint) {
        let geoPoint = globalMap.convertPoint(toPoint, toCoordinateFromView: globalMap)
        currentPin!.setCoordinate(geoPoint)
    }

    func storePin() {
        
        let newPin = Pin(lat: Double(currentPin!.coordinate.latitude), lon: Double(currentPin!.coordinate.longitude), context: sharedContext)
        globalMap.removeAnnotation(currentPin!)
        globalMap.addAnnotation(newPin)
        CoreDataStackManager.sharedInstance().saveContext()
        FlickrClient.sharedInstance.getFlickrPicsWithLatLon(newPin.lat, longitude: newPin.lon)
    }
    
        


}

