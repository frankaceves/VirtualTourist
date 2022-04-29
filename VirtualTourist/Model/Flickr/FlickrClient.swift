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
        let url_m: String?
    }
    struct APIError: Decodable {
        let stat: String
        let code: Int
        let message: String
    }
    
    
    var photoResults: [Data] = []
    var searchResultsCount = 0
    var photoURLs: [URL] = []
    
    // MARK: HELPER FUNCTIONS
    
    // create a URL from parameters
    // SOURCE: used in The Movie Manager udacity sub-project (Section 5: Network Requests)
    func clearFlickrResults() {
        photoResults = []
        photoURLs = []
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
    enum DataTaskError {
        case statusCodeNot2XX
        case couldNotDownloadData
        case jsonDecodingError
    }
    func downloadPhotosForLocation1(lat: Double, lon: Double, _ completionHandlerForDownload: @escaping (_ result: Bool, _ urls: [URL]?) -> Void) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = Constants.Flickr.APIScheme
        urlComponents.host = Constants.Flickr.APIHost
        urlComponents.path = Constants.Flickr.APIPath
        
        let searchQueryItems = [
            URLQueryItem(name: Constants.FlickrParameterKeys.Method, value: Constants.FlickrParameterValues.SearchMethod),
            URLQueryItem(name: Constants.FlickrParameterKeys.APIKey, value: Constants.FlickrParameterValues.APIKey),
            URLQueryItem(name: Constants.FlickrParameterKeys.Latitude, value: String(lat)),
            URLQueryItem(name: Constants.FlickrParameterKeys.Longitude, value: String(lon)),
            URLQueryItem(name: Constants.FlickrParameterKeys.Radius, value: Constants.FlickrParameterValues.ResponseRadius),
            URLQueryItem(name: Constants.FlickrParameterKeys.ResultsPerPage, value: Constants.FlickrParameterValues.ResponseResultsPerPage),
            URLQueryItem(name: Constants.FlickrParameterKeys.Extras, value: Constants.FlickrParameterValues.ResponseExtras),
            URLQueryItem(name: Constants.FlickrParameterKeys.format, value: Constants.FlickrParameterValues.ResponseFormat),
            URLQueryItem(name: Constants.FlickrParameterKeys.NoJSONCallback, value: Constants.FlickrParameterValues.DisableJSONCallback)
            ]
        urlComponents.queryItems = searchQueryItems
        
        guard let testURL = urlComponents.url else {
            // TODO: HANDLE ERROR
            fatalError("can't construct url from components")
        }
        
        let session = URLSession.shared
        
        let request = URLRequest(url: testURL)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard (error == nil) else{
                print("error downloading photos: \(error!)")
                return
            }
            
            // NOTE: - STATUS CODE RETURNS 200 EVEN WITH INVALID API KEY OR OTHER BAD PARAMS
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("\(DataTaskError.statusCodeNot2XX)")
                return
            }
            
            guard let data = data else {
                print("\(DataTaskError.couldNotDownloadData)")
                return
            }
            
            guard let photosInfo = try? JSONDecoder().decode(Photos.self, from: data) else {
                print("\(DataTaskError.jsonDecodingError)")
                if let result = try? JSONDecoder().decode(APIError.self, from: data) {
                    print(result.message)
                }
                return
            }
            
            // HOW MANY SEARCH RESULTS DID YOU GET?
            self.searchResultsCount = photosInfo.photos.photo.count
            print("search results count: \(self.searchResultsCount)")
            
            // PULL PAGES INFO HERE
            let totalPages = photosInfo.photos.pages
            
            // CREATE RANDOM PAGE
            //let pageLimit = min(totalPages, 100)
            let randomPageNumber = Int(arc4random_uniform(UInt32(totalPages)))// + 1
            print("random page number = \(randomPageNumber)")
            
            // TODO: CALL FUNC THAT EXECUTES SECOND NETWORK REQUEST WITH PAGE NUMBER
            self.searchForRandomPhotosUsingRequest(request: request, pageNumber: randomPageNumber, completionHandlerfForRandomPhotoSearch: { (success, urlsToDownload) in
                guard let urlsToDownload = urlsToDownload else {
                    print("no urls returned from random search")
                    return
                }
                
                if success {
                    self.photoURLs.append(contentsOf: urlsToDownload)
                    print("photoURLs count: \(self.photoURLs.count)")
                    completionHandlerForDownload(success, urlsToDownload)
                } else {
                    print("error with searchForRandomPageUsingRequest")
                }
            })
            
        }
        task.resume()
    }
    
    func searchForRandomPhotosUsingRequest(request: URLRequest, pageNumber: Int, completionHandlerfForRandomPhotoSearch: @escaping (_ result: Bool, _ urls: [URL]?) -> Void) {
        //take urlString parameter from previous method
        //append page number to it
        guard let requestURLString = request.url?.absoluteString else {
            // TODO: HANDLE ERROR - send failure completion with alert presentation
            fatalError("could not get url string from request")
        }
        let urlStringWithPageNumber = requestURLString.appending("&\(Constants.FlickrParameterKeys.Page)=\(pageNumber)")
        
        guard let url = URL(string: urlStringWithPageNumber) else {
            // TODO: HANDLE ERROR - send failure completion with alert presentation
            fatalError("could not create URL from urlStringWithPage param")
        }
        
        let session = URLSession.shared
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data, response, error) in
            guard (error == nil) else{
                // TODO: HANDLE ERROR - send failure completion with alert presentation
                fatalError("error downloading photos: \(error!)")
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                // TODO: HANDLE ERROR - send failure completion with alert presentation
                fatalError("request returned status code other than 2XX")
            }
            
            guard let data = data else {
                // TODO: HANDLE ERROR - send failure completion with alert presentation
                fatalError("could not download data: \(#function)")
            }
            
            
            // move to do catch block for error handling
            var urlArray = [URL]()
            do {
                let randomPhotosInfo = try JSONDecoder().decode(Photos.self, from: data)
                randomPhotosInfo.photos.photo.forEach { photo in
                    if let photoURLString = photo.url_m, let photoURL = URL(string: photoURLString) {
                          urlArray.append(photoURL)
                    }
                }
                completionHandlerfForRandomPhotoSearch(true, urlArray)
            } catch {
                fatalError("error in decoding process: \(error)")
            }
        }
        task.resume()
    }
    
    func makeImageDataFrom1(flickrURL: URL) -> Data? {
        return try? Data(contentsOf: flickrURL)
    }
    
    // MARK: SHARED INSTANCE
    
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static let sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}
