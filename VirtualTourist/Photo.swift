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
    @NSManaged var imageURL: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(imageUrl: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)
        super.init(entity: entity!, insertIntoManagedObjectContext: context)

        imageURL = imageUrl
    }
    
    var image: UIImage? {
        // return a previously stored image, if exists, otherwise nil
        get {
            let fileURL = dirFilePathLocator()
            if NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!) {
                
                return UIImage(contentsOfFile: fileURL.path!)!
            }
            return nil
        }
        // When an Photo's image is set to nil, delete it from Docs directory.
        // Otherwise store the new image as a JPEG in Docs directory.
        set {
            if newValue == nil {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(dirFilePathLocator().path!)
                } catch {
                }
                return
            } else {
                let data = UIImageJPEGRepresentation(newValue!, 1.0)
                data?.writeToFile(dirFilePathLocator().path!, atomically: true)
            }
        }
        
    }
    // make sure photo is removed from Documents directory before deletion
    override func prepareForDeletion() {
        image = nil
    }
    // helper function to make a path to the Docs directory using this Photo's imageURL property as ID
    func dirFilePathLocator() -> NSURL {
        let fileName = NSString(string: imageURL).lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let pathArray = [dirPath, fileName]
        
        return NSURL.fileURLWithPathComponents(pathArray)!
    }
    
    
}