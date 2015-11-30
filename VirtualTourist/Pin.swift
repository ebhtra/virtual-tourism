//
//  Pin.swift
//  VirtualTourist
//
//  Created by Ethan Haley on 11/20/15.
//  Copyright © 2015 Ethan Haley. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject, MKAnnotation {
    
    @NSManaged var pics: [Photo]
    @NSManaged var lat: Double
    @NSManaged var lon: Double
    
    // MKMapView will not add MKAnnotations from fetched CoreData Pins without a coordinate getter:
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(lat: Double, lon: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)
        self.lat = lat
        self.lon = lon
    }
    
    func setCoordinate(toPoint: CLLocationCoordinate2D) {
        //To comply with KVO in order to drag a pin before dropping it
        willChangeValueForKey("coordinate")
        self.lat = toPoint.latitude
        self.lon = toPoint.longitude
        didChangeValueForKey("coordinate")
    }
    
    
}