//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Ethan Haley on 11/28/15.
//  Copyright © 2015 Ethan Haley. All rights reserved.
//

import UIKit
import CoreData

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    let baseGeoString = "\(Constants.BASE_URL)?method=\(Constants.METHOD_NAME)&api_key=\(Constants.API_KEY)&format=\(Constants.DATA_FORMAT)&nojsoncallback=\(Constants.NO_JSON_CALLBACK)&extras=\(Constants.EXTRAS)"
   
    
    func getFlickrPicsFromPin(fromPin: Pin) {
        let minLat = max(fromPin.lat - Constants.BOUNDING_BOX_HALF_HEIGHT , -90.0)
        let minLon = max(fromPin.lon - Constants.BOUNDING_BOX_HALF_WIDTH, -180.0)
        let maxLat = min(fromPin.lat + Constants.BOUNDING_BOX_HALF_HEIGHT, 90.0)
        let maxLon = min(fromPin.lon + Constants.BOUNDING_BOX_HALF_WIDTH, 180.0)
        
        let session = NSURLSession.sharedSession()
        let bbox = "&bbox=\(minLat)%2C\(minLon)%2C\(maxLat)%2C\(maxLon)"
        print(bbox)
        let urlString = baseGeoString + bbox
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Could not complete the request \(error)")
            } else {
                do {
                    let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                    print(parsedResult)
                    if let photosDictionary = parsedResult!.valueForKey("photos") as? [String:AnyObject] {
                        
                        var totalPhotosVal = 0
                        if let totalPhotos = photosDictionary["total"] as? String {
                            print("number of photos=\(totalPhotos)")
                            totalPhotosVal = (totalPhotos as NSString).integerValue
                        }
                        
                        if totalPhotosVal > 0 {
                            if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                let _ = photosArray.map() { (dict: [String : AnyObject]) -> Photo in
                                    let imageData = NSData(contentsOfURL: NSURL(string: dict["url_m"] as! String)!)
                                    let newPhoto = Photo(image: UIImage(data: imageData!)!, context: self.sharedContext)
                                    newPhoto.site = fromPin
                                    return newPhoto
                                }
                                CoreDataStackManager.sharedInstance().saveContext()
                                
                                /*
                                for dict in photosArray {
                                    if let picURL = dict["url_m"] as? String {
                                        let dataURL = NSURL(string: picURL!)
                                        if let imageData = NSData(contentsOfURL: dataURL!) {
                                            let newPhoto = Photo(image: UIImage(data: imageData)!, context: self.sharedContext)
                                            newPhoto.site = fromPin
                                            
                                        }
                                    }
                                }
*/
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
        task.resume()
        
    }
}
