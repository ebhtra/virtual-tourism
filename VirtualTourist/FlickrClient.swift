//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Ethan Haley on 11/28/15.
//  Copyright © 2015 Ethan Haley. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    
    static let sharedInstance = FlickrClient()
    
    let baseGeoString = Constants.BASE_URL + "?method=" + Constants.METHOD_NAME + "&api_key=" + Constants.API_KEY  + "&format=" + Constants.DATA_FORMAT + "&nojsoncallback=" + Constants.NO_JSON_CALLBACK + "&extras=" + Constants.EXTRAS
    
    func getFlickrPicsWithLatLon(latitude: Double, longitude: Double) {
        let minLat = max(latitude - Constants.BOUNDING_BOX_HALF_HEIGHT , -90.0)
        let minLon = max(longitude - Constants.BOUNDING_BOX_HALF_WIDTH, -180.0)
        let maxLat = min(latitude + Constants.BOUNDING_BOX_HALF_HEIGHT, 90.0)
        let maxLon = min(longitude + Constants.BOUNDING_BOX_HALF_WIDTH, 180.0)
        
        let session = NSURLSession.sharedSession()
        let urlString = baseGeoString + "&bbox=\(minLat)%2C\(minLon)%2C\(maxLat)%2C\(maxLon)"
        let url = NSURL(string: urlString)!
        print(url)
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                print("Could not complete the request \(error)")
            } else {
                do {
                    let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
                    
                    if let photosDictionary = parsedResult!.valueForKey("photos") as? [String:AnyObject] {
                        
                        var totalPhotosVal = 0
                        if let totalPhotos = photosDictionary["total"] as? String {
                            print(totalPhotos)
                            totalPhotosVal = (totalPhotos as NSString).integerValue
                        }
                        
                        if totalPhotosVal > 0 {
                            if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                                
                                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                                
                                //let photoTitle = photoDictionary["title"] as? String
                                let imageUrlString = photoDictionary["url_m"] as? String
                                //let imageURL = NSURL(string: imageUrlString!)
                                
                                print(imageUrlString)
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
