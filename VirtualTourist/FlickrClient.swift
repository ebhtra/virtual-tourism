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
    // singleton instance stored as static constant
    static let sharedInstance = FlickrClient()
    
    let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
    
    // hard-coding most of the parameters since only one type of search used by app.
    // would want to abstract this for expanded app functionality
    let baseGeoString = "\(Constants.BASE_URL)?method=\(Constants.METHOD_NAME)&api_key=\(Constants.API_KEY)&format=\(Constants.DATA_FORMAT)&nojsoncallback=\(Constants.NO_JSON_CALLBACK)&extras=\(Constants.EXTRAS)&per_page=\(Constants.PHOTOS_PER_PAGE)"
    //counters to help avoid repetitious photo displays
    var nextPage = 0
    var numPages = 0
    
    func getFlickrPicsFromPin(fromPin: Pin) {
        //cycle through available pages, avoid "page 0"
        nextPage++
        if nextPage > numPages {
            nextPage = max(1, (nextPage+1) % (numPages+1))   // +1 is to avoid %0
        }
        //make sure bbox bounds are legit
        let minLat = max(fromPin.lat - Constants.BOUNDING_BOX_HALF_HEIGHT , -90.0)
        let minLon = max(fromPin.lon - Constants.BOUNDING_BOX_HALF_WIDTH, -180.0)
        let maxLat = min(fromPin.lat + Constants.BOUNDING_BOX_HALF_HEIGHT, 90.0)
        let maxLon = min(fromPin.lon + Constants.BOUNDING_BOX_HALF_WIDTH, 180.0)
        //build the rest of the request based on pin location and page number
        let session = NSURLSession.sharedSession()
        let bbox = "&bbox=\(minLon)%2C\(minLat)%2C\(maxLon)%2C\(maxLat)"
        let urlString = baseGeoString + bbox + "&page=\(nextPage)"
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                //fail silently from user's perspective
                print("Could not complete the request \(error)")
            } else {
                do {
                    let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                    
                    if let photosDictionary = parsedResult!.valueForKey("photos") as? [String:AnyObject] {
                            
                        if let totalPages = photosDictionary["pages"] as? Int {
                            //set numPages for when user reloads photos.
                            self.numPages = totalPages
                            //if nextPage turns out to be set too high from the previous Pin, reset nextPage to 0 and call this function again
                            if self.numPages > 0 && self.numPages < self.nextPage {
                                self.nextPage = 0
                                self.getFlickrPicsFromPin(fromPin)
                            }
                        }
                        
                        var totalPhotosVal = 0
                        if let totalPhotos = photosDictionary["total"] as? String {
                            totalPhotosVal = (totalPhotos as NSString).integerValue
                        }
                        
                        if totalPhotosVal > 0 {
                            //let numFrames = min(totalPhotosVal, Int(Constants.PHOTOS_PER_PAGE)!)
                            
                            self.sharedContext.performBlockAndWait() {
                                if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                    let _ = photosArray.map() { (dict: [String : AnyObject]) -> Photo in
                                        let imageUrl = dict["url_m"] as! String
                                        //create new Photo managed objects for each flickr photo returned
                                        let newPhoto = Photo(imageUrl: imageUrl, context: self.sharedContext)
                                        //link the Photo to current pin for inverse relationship
                                        newPhoto.site = fromPin
                                        //store the image in the new Photo
                                        newPhoto.image = UIImage(data: NSData(contentsOfURL: NSURL(string: imageUrl)!)!)
                                        
                                        return newPhoto
                                    }
                                    CoreDataStackManager.sharedInstance().saveContext()
                                }
                            }
                        } 
                    }
                } catch {
                    //fail silently from user's perspective
                    print(error)
                }
            }
        }
        task.resume()
        
    }
}
