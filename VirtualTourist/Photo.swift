//
//  Photo.swift
//  VirtualTourist
//
//  Created by Ethan Haley on 11/20/15.
//  Copyright © 2015 Ethan Haley. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Photo: NSManagedObject {
    
    @NSManaged var site: Pin
    @NSManaged var image: UIImage
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(image: UIImage, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)

        self.image = image
    }
    
}