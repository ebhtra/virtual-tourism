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
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(lat: Double, lon: Double, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)
        super.init(entity: entity!, insertInto: context)
        self.lat = lat
        self.lon = lon
    }
    
    func setCoordinate(_ toPoint: CLLocationCoordinate2D) {
        //To comply with KVO in order to drag a pin before dropping it
        willChangeValue(forKey: "coordinate")
        self.lat = toPoint.latitude
        self.lon = toPoint.longitude
        didChangeValue(forKey: "coordinate")
    }
    
    
}
