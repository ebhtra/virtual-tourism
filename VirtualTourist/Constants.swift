//
//  Constants.swift
//  VirtualTourist
//
//  Created by Ethan Haley on 11/19/15.
//  Copyright © 2015 Ethan Haley. All rights reserved.
//

import Foundation

struct Constants {
    
    static let BASE_URL = "https://api.flickr.com/services/rest/"
    static let METHOD_NAME = "flickr.photos.search"
    static let API_KEY = "2c5b25cd7c3813d59f8455da50110964"
    static let EXTRAS = "url_m"
    static let SAFE_SEARCH = "1"
    static let DATA_FORMAT = "json"
    static let NO_JSON_CALLBACK = "1"
    static let BOUNDING_BOX_HALF_WIDTH = 0.1
    static let BOUNDING_BOX_HALF_HEIGHT = 0.1
    static let PHOTOS_PER_PAGE = "30"
}
