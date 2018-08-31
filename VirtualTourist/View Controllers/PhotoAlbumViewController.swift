//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Frank Anthony Aceves on 6/24/18.
//  Copyright © 2018 Frank Aceves. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UICollectionViewDelegate {
    
    var dataController: DataController!
    
    //indexes to track
    var insertedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    
    var thread = Thread.current
    //the location passed from Travel Location Map VC, and whose photos will be displayed
    var pin: Pin!
    
    //the ID passed from the selected pin in prev VC
    var objectID: NSManagedObjectID!
    
    var location: NSManagedObject!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var currentPinLatitude: Double!
    var currentPinLongitude: Double!
    var currentCoordinate: CLLocationCoordinate2D!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    
    
    var downloadedPhotos = [Data]()
    var photoInfo: [FlickrClient.Photo]?
    var urlsToDownload = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        configMap()
        setupFetchedResultsController()
        // Do any additional setup after loading the view.
        //print("view Did Load")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view WIll Appear")
        print("current pin info: \(pin)")
        setupFetchedResultsController()
        downloadPhotosOrFetchPhotos()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //print("view WILL disappear.")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //print("view DID disappear")
        
        fetchedResultsController = nil
        clearAll()
    }
    
    func clearAll() {
        print("Clearing all local arrays")
        photoInfo = []
        downloadedPhotos = []
        urlsToDownload = []
        FlickrClient.sharedInstance().clearFlickrResults()
    }
    
    fileprivate func downloadPhotos(_ completionForDownload: @escaping (_ success: Bool) -> Void) {
        print("downloadPhotos")
        
        clearAll()
        //FlickrClient.sharedInstance().downloadPhotosForLocation(lat: pin.latitude, lon: pin.longitude)
        FlickrClient.sharedInstance().downloadPhotosForLocation1(lat: pin.latitude, lon: pin.longitude) { (success, urls) in
            
            guard let urls = urls else {
                print("no url's returned in completion handler")
                return
            }
            
            if (success == false) {
                print("JSON DL did not complete")
                return
            }
            
            //print("photosInfo: \(result.photos.photo)")
            //self.photoInfo = result.photos.photo
            
            
            self.urlsToDownload.append(contentsOf: urls)
            
            DispatchQueue.main.async {
                //print("thread during url core data save: \(self.thread)")
                for url in urls {
                    let photo = Photo(context: self.dataController.viewContext)
                    photo.name = url.absoluteString
                    photo.location = self.pin
                    try? self.dataController.viewContext.save()
                    //print("saved CoreData photo info: \(photo)")
                }
//                print("reloading Data after url download")
//                self.collectionView.reloadData()
                print("urlsToDownload count: \(self.urlsToDownload.count)\nurls: \(self.urlsToDownload)")
                completionForDownload(true)
            }
            
            
        }
        
    }
    
    func downloadPhotosOrFetchPhotos() {
        print("downloadPhotosOrFetchPhotos")
        if let photoCount = pin.photos?.count {
            if photoCount <= 0 {
                downloadPhotos({ (success) in
                    if success == true {
                        print("success completion")
                    }
                })
            } else {
                //FETCH PHOTOS
                //fetchPhotos()
                
            }
        } else {
            print("there are no photos to load.")
        }
    }
    
    private func reloadView() {
        print("collectionView reloadData")
        collectionView.reloadData()
    }
    
    private func resetDownloadedPhotos() {
        downloadedPhotos = []
    }
    
    fileprivate func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func fetchPhotos() {
        print("fetchPhotos")
        resetDownloadedPhotos()
        performFetch()
        
        // testing Fetch
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            print("fetched Objects count: \(fetchedObjects.count)")
            for photo in fetchedObjects {
                if let imageURLstring = photo.name, let imageURL = URL(string: imageURLstring) {
                    urlsToDownload.append(imageURL)
                } else {
                    print("no image data present in fetched Object.")
                }
            }
        } else {
            print("nothing was fetched")
        }
    }
    
    
    @IBAction func newCollectionButtonPressed(_ sender: UIBarButtonItem) {
        
        
        //print("DL photo count: \(downloadedPhotos.count)")
        
        //fetch request is already established
        //NSBatchDeleteRequest
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            print("confirming fetched count: \(fetchedObjects.count)")
            for photo in fetchedObjects {
                print("photo info: \(photo.image!.description)")
                dataController.viewContext.delete(photo)
            }
            //fetchPhotos()
            //print("FRC final count count = \(fetchedResultsController.fetchedObjects?.count)")
            //savePhotos()
        } else {
            print("no fetched photos present to delete for NewCollection")
        }
        
        //clear any photos from Flickr search, or local arrays
        clearAll()
        print("Flickr photo results count: \(FlickrClient.sharedInstance().photoResults.count)")
        
        //download new set of photos
        downloadPhotos { (success) in
            if success == true {
                print("success completion for new collection")
            }
        }
    }
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate: NSPredicate?
        
        predicate = NSPredicate(format: "location == %@", pin)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "location", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        //print("fetchRequest: \(fetchRequest)")
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func configMap() {
        let lat = currentCoordinate.latitude
        let long = currentCoordinate.longitude
        
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        let mapSpan = MKCoordinateSpanMake(0.02, 0.02)
        let region = MKCoordinateRegion(center: coordinate, span: mapSpan)
        self.mapView.setRegion(region, animated: true)
        
        self.mapView.addAnnotation(annotation)
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin2"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.red
            pinView?.animatesDrop = false
            
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // MARK: - PHOTO DOWNLOAD FUNCTIONS
    
    
    // MARK: - PERSIST PHOTOS
    
    func savePhotos() {
        if self.dataController.viewContext.hasChanges {
            print("there were changes.  Attempting to save.")
            do {
                try self.dataController.viewContext.save()
            } catch {
                print("an error occurred while saving: \(error.localizedDescription)")
            }
        } else {
            print("no changes were made.  Not saving.")
        }
    }
    
    // MARK: - COLLECTION VIEW
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("***Collection View: Number of items in section***")
        //print("numItemsInSection count: \(fetchedResultsController.sections?[section].numberOfObjects)")
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0 {
            print("***Collection View: Cell For Row at Index Path***")
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! LocationImageCollectionViewCell
        //cell.locationPhoto.image = nil
        
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.frame = cell.bounds
        cell.backgroundColor = UIColor.darkGray
        cell.locationPhoto.alpha = 0.5
        cell.addSubview(activityIndicator)
        cell.locationPhoto.image = #imageLiteral(resourceName: "Placeholder - 120x120")
        activityIndicator.startAnimating()
        
        let aPhoto = fetchedResultsController.object(at: indexPath)
        
        //print("aphoto BEFORE: \(aPhoto)")
        if aPhoto.image != nil {
            //print("showing fetched image via FRC")
            cell.locationPhoto.image = UIImage(data: aPhoto.image!)
            cell.locationPhoto.alpha = 1.0
            activityIndicator.stopAnimating()
            return cell
        } else {
            
            
            DispatchQueue.global(qos: .background).async {
                if let urlString = aPhoto.name, let imageURL = URL(string: urlString), let image = self.downloadSinglePhoto1(photoURL: imageURL) {
                    
                    // do not save to coreData here!!!
                    //print("image data present.")
                    DispatchQueue.main.async {
                        cell.locationPhoto.image = UIImage(data: image)
                        cell.locationPhoto.alpha = 1.0
                        activityIndicator.stopAnimating()
                        if aPhoto.image == nil {
                            print("still nil")
                            aPhoto.image = image
                            do {
                                try self.dataController.viewContext.save()
                            } catch {
                                print("error saving in cellforItem: \(error.localizedDescription)")
                            }
                        }
                        //print("aphoto image: \(aPhoto.image)")
                        
                        //print("aphoto info after: \(aPhoto)")
                    }
                    
                }
            }
            
        }
        
        return cell
    }
    
    
    func downloadSinglePhoto1(photoURL: URL) -> Data? {
        //print("downloading")
        return FlickrClient.sharedInstance().makeImageDataFrom1(flickrURL: photoURL)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        print("did select: \(photoToDelete.image!)")

        
        //collectionView.deleteItems(at: [indexPath])

        dataController.viewContext.delete(photoToDelete)
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //clear arrays
        insertedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            print("insert object")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .update:
            print("update object")
            updatedIndexPaths.append(indexPath!)
            break
        case .delete:
            print("delete object")
            deletedIndexPaths.append(indexPath!)
            break
        default:
            print("DEFAULT - no other action needed")
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                print("indexPathinfo: \(indexPath)")
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                print("indexPathinfo: \(indexPath)")
                self.collectionView.deleteItems(at: [indexPath])
            }
        }, completion: nil)
    }
}
