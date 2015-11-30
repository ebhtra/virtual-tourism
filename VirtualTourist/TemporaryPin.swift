//
//  TemporaryPin.swift
//  VirtualTourist
//
//  Created by Ethan Haley on 11/24/15.
//  Copyright © 2015 Ethan Haley. All rights reserved.
//

import Foundation
import MapKit
/* This class is used to create temporary pins on the map
   so the user can drag them before having dropped them. */
class TemporaryPin: NSObject, MKAnnotation {
    
    var location = CLLocationCoordinate2D()
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return location
        }
    }
    
    func setCoordinate(toPoint: CLLocationCoordinate2D) {
        //To comply with KVO
        willChangeValueForKey("coordinate")
        self.location = toPoint
        didChangeValueForKey("coordinate")
    }
}