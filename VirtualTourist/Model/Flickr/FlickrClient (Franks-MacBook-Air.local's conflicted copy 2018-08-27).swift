//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Frank Anthony Aceves on 6/24/18.
//  Copyright © 2018 Frank Aceves. All rights reserved.
//

import UIKit
import CoreData

class FlickrClient: NSObject {
    var dataController: DataController!
    
    struct Photos: Decodable {
        let photos: PhotoInfo
        let stat: String
    }
    
    struct PhotoInfo: Decodable {
        let photo: [Photo]
        let page: Int
        let pages: Int
    }
    
    struct Photo: Decodable {
        //    Variables needed:
        //    Farm ID = “farm”
        //    Server ID = “server”
        //    ID = “id”
        //    Secret = “secret”
        let farm: Int
        let server: String
        let id: String
        let secret: String
    }
    
    
    var photoResults: [Data] = []
    var searchResultsCount = 0
    
    // MARK: HELPER FUNCTIONS
    
    // create a URL from parameters
    // SOURCE: used in The Movie Manager udacity sub-project (Section 5: Network Requests)
    func clearPhotoResults() {
        photoResults = []
    }
    
    func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        var components = URLComponents()
        components.scheme = FlickrClient.Constants.Flickr.APIScheme
        components.host = FlickrClient.Constants.Flickr.APIHost
        components.path = FlickrClient.Constants.Flickr.APIPath
        
//        for (key, value) in parameters {
//            let queryItem = URLQueryItem(name: key, value: "\(value)")
//            //components.queryItems?.append(queryItem)
//        }
        
        return components.url!
    }
    func downloadPhotosForLocation1(lat: Double, lon: Double, _ completionHandlerForDownload: @escaping (_ result: Bool, _ photoInfo: Photos?) -> Void) {
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=ad57c918d7705a17a075a02858b94f59&lat=\(lat)&lon=\(lon)&radius=1&per_page=21&format=json&nojsoncallback=1"
        let url = URL(string: urlString)
        
        let session = URLSession.shared
        
        let request = URLRequest(url: url!)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard (error == nil) else{
                print("error downloading photos: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("request returned status code other than 2XX")
                return
            }
            
            guard let data = data else {
                print("could not download data")
                return
            }
            
            guard let photosInfo = try? JSONDecoder().decode(Photos.self, from: data) else {
                print("error in decoding process")
                return
            }
            
            
            // HOW MANY SEARCH RESULTS DID YOU GET?
            self.searchResultsCount = photosInfo.photos.photo.count
            print("search results count: \(self.searchResultsCount)")
            completionHandlerForDownload(true, photosInfo)
            
            
            
            // PULL PAGES INFO HERE
            //let totalPages = photosInfo.photos.pages
            
            // CREATE RANDOM PAGE
            //let pageLimit = min(totalPages, 100)
            //let randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            //print("random page number = \(randomPageNumber)")
            
            // TODO: CALL FUNC THAT EXECUTES SECOND NETWORK REQUEST WITH PAGE NUMBER
            
        }
        task.resume()
    }
        
    func downloadPhotosForLocation(lat: Double, lon: Double) /*, _ completionHandlerfForPhotoDownload: @escaping (_ results: [Data]?, _ error: String?) -> Void */ {
        let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=ad57c918d7705a17a075a02858b94f59&lat=\(lat)&lon=\(lon)&radius=1&per_page=21&format=json&nojsoncallback=1"
        let url = URL(string: urlString)
        
        let session = URLSession.shared
        
        let request = URLRequest(url: url!)
        //print("request: \(request)")
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard (error == nil) else{
                print("error downloading photos: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("request returned status code other than 2XX")
                return
            }
            
            guard let data = data else {
                print("could not download data")
                return
            }
            
            guard let photosInfo = try? JSONDecoder().decode(Photos.self, from: data) else {
                print("error in decoding process")
                return
            }
            
            // HOW MANY SEARCH RESULTS DID YOU GET?
            self.searchResultsCount = photosInfo.photos.photo.count
            print("search results count: \(self.searchResultsCount)")
            
            // PULL PAGES INFO HERE
            let totalPages = photosInfo.photos.pages
            
            // CREATE RANDOM PAGE
            //let pageLimit = min(totalPages, 100)
            //let randomPageNumber = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            //print("random page number = \(randomPageNumber)")
            
            // TODO: CALL FUNC THAT EXECUTES SECOND NETWORK REQUEST WITH PAGE NUMBER
            
        }
        task.resume()
        
    }
    
    func searchForRandomPhotos(urlString: String, pageNumber: Int, completionHandlerfForRandomPhotoSearch: @escaping (_ results: [Data]?, _ error: String?) -> Void) {
        //print("***search for random photos called")
        //take urlString parameter from previous method
        //append page number to it
        let urlStringWithPageNumber = urlString.appending("&page=\(pageNumber)")
        //print("new urlString: \(urlStringWithPageNumber)")
        
        let url = URL(string: urlStringWithPageNumber)
        
        let session = URLSession.shared
        
        let request = URLRequest(url: url!)
        //print("request: \(request)")
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard (error == nil) else{
                print("error downloading photos: \(error!)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("request returned status code other than 2XX")
                return
            }
            
            guard let data = data else {
                print("could not download data")
                return
            }
            
            guard let randomPhotosInfo = try? JSONDecoder().decode(Photos.self, from: data) else {
                print("error in decoding process")
                return
            }
            
            for photo in randomPhotosInfo.photos.photo {
                self.makeImageFrom(photo: photo)
            }
            
            //print("photoResults count = \(self.photoResults.count)")
            //print("photoResults = \(self.photoResults)")
            completionHandlerfForRandomPhotoSearch(self.photoResults, nil)
            
        }
        task.resume()
        //TODO: MOVE makeImageFrom func to secondary function
        //TODO: SECONDARY FUNCTION should pass photo info (iteration)
        //TODO: iterate through second set of results - make image from...
            
            //completion hander should be executed in second function with second network request.
            //completionHandlerfForPhotoDownload(self.photoResults, nil)
        
    }
    
    func makeImageFrom(photo: Photo){
        let farm = photo.farm
        let server = photo.server
        let id = photo.id
        let secret = photo.secret
        
        let urlString = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
        let imageUrl = URL(string: urlString)!
        //print("imageURL: \(imageUrl)")
        
        if let imageData = try? Data(contentsOf: imageUrl) {
            //collect data only for CoreData
            photoResults.append(imageData)
        }
    }
    
    func makeImageDataFrom1(photo: Photo) -> Data?{
        let farm = photo.farm
        let server = photo.server
        let id = photo.id
        let secret = photo.secret
        
        let urlString = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
        let imageUrl = URL(string: urlString)!
        //print("imageURL: \(imageUrl)")
        
//        if let imageData = try? Data(contentsOf: imageUrl) {
//            //collect data only for CoreData
//            //photoResults.append(imageData)
//            return imageData
//        } else {
//            return nil
//        }
        return try? Data(contentsOf: imageUrl)
    }
    
    // MARK: SHARED INSTANCE
    
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static let sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}
