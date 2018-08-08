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
    
    func downloadPhotosForLocation(lat: Double, lon: Double, _ completionHandlerfForPhotoDownload: @escaping (_ results: [Data]?, _ error: String?) -> Void) {
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
            
            if let photosInfo = try? JSONDecoder().decode(Photos.self, from: data) {
                //print("decoded")
                
                for photo in photosInfo.photos.photo {
                    //make url from info provided
                    self.makeImageFrom(photo: photo)
                }
                
                completionHandlerfForPhotoDownload(self.photoResults, nil)
                
            } else {
                //print("not decoded")
                completionHandlerfForPhotoDownload(nil, "could not decode photo Data")
            }
            
        }
        task.resume()
        
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
    
    // MARK: SHARED INSTANCE
    
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static let sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}
