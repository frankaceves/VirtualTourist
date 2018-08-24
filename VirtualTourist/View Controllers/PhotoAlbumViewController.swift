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
    
    //the location passed from Travel Location Map VC, and whose photos will be displayed
    var pin: Pin!
    var photo: Photo?
    
    //the ID passed from the selected pin in prev VC
    var objectID: NSManagedObjectID!
    
    var location: NSManagedObject!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var currentPinLatitude: Double!
    var currentPinLongitude: Double!
    var currentCoordinate: CLLocationCoordinate2D!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    
    
    var downloadedPhotos: [Data] = []
    var photoInfo: [FlickrClient.Photo]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        configMap()
        // Do any additional setup after loading the view.
        //print("view Did Load")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view WIll Appear")
        //print("dl Photo array: \(downloadedPhotos)")
        //print("the pin that was passed: \(pin!)")
        //print("passed pin photos: \(String(describing: pin.photos?.count))")
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
        savePhotos()
        fetchedResultsController = nil
        photoInfo = nil
        downloadedPhotos = []
        //print("dl photo after disappear: \(downloadedPhotos)")
        FlickrClient.sharedInstance().clearPhotoResults()
    }
    
    fileprivate func downloadPhotos() {
        print("downloadPhotos")
        //FlickrClient.sharedInstance().downloadPhotosForLocation(lat: pin.latitude, lon: pin.longitude)
        FlickrClient.sharedInstance().downloadPhotosForLocation1(lat: pin.latitude, lon: pin.longitude) { (success, result) in
            if (success == false) {
                print("JSON DL did not complete")
                return
            }
            
            guard let result = result else {
                print("no results returned in completion handler")
                return
            }
            
            print("photosInfo: \(result.photos.photo)")
            self.photoInfo = result.photos.photo
            
            
            DispatchQueue.main.async {
                self.reloadView()
            }
        }
    }
    
    func downloadPhotosOrFetchPhotos() {
        print("downloadPhotosOrFetchPhotos")
        if let photoCount = pin.photos?.count {
            if photoCount <= 0 {
                downloadPhotos()
                //fetchPhotos()
            } else {
                //FETCH PHOTOS
                //print("load fetched photos")
                fetchPhotos()
                reloadView()
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
            //print("fetched Objects count: \(fetchedObjects.count)")
            for photo in fetchedObjects {
                if let imageData = photo.image {
                    downloadedPhotos.append(imageData)
                }
            }
        }
    }
    @IBAction func newCollectionButtonPressed(_ sender: UIBarButtonItem) {
        
        
        //print("DL photo count: \(downloadedPhotos.count)")
        
        //fetch request is already established
        //NSBatchDeleteRequest
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            //print("confirming fetched count: \(fetchedObjects.count)")
            for photo in fetchedObjects {
                //print("photo info: \(photo.image!.description)")
                dataController.viewContext.delete(photo)
            }
            
        }
        
        fetchPhotos()
        //print("FRC final count count = \(fetchedResultsController.fetchedObjects?.count)")
        savePhotos()
        
        FlickrClient.sharedInstance().clearPhotoResults()
        //print("Flickr photo results count: \(FlickrClient.sharedInstance().photoResults.count)")
        //download new set of photos
        downloadPhotos()
    }
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate: NSPredicate?
        
        predicate = NSPredicate(format: "location == %@", pin)
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "image", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        //print("fetchRequest: \(fetchRequest)")
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
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
    func getPhotos(lat: Double, lon: Double) {
        print("getPhotos")
        FlickrClient.sharedInstance().downloadPhotosForLocation(lat: lat, lon: lon)
    }
    
    // MARK: - PERSIST PHOTOS
    
    func savePhotos() {
        if dataController.viewContext.hasChanges {
            print("there were changes.  Attempting to save.")
            do {
                try dataController.viewContext.save()
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
        
        return fetchedResultsController.sections?[section].numberOfObjects ?? 21
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0 {
            print("***Collection View: Cell For Row at Index Path***")
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! LocationImageCollectionViewCell
        cell.locationPhoto.image = #imageLiteral(resourceName: "Placeholder - 120x120")
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.frame = cell.bounds
        cell.backgroundColor = UIColor.darkGray
        cell.locationPhoto.alpha = 0.5
        cell.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            if let imageData = fetchedObjects[indexPath.item].image {
                print("dataPresent: \(imageData)")
                cell.locationPhoto.image = UIImage(data: imageData)
                cell.locationPhoto.alpha = 1.0
                activityIndicator.stopAnimating()
            }
        } else {
            if let photoInfo = photoInfo {
                //print("Photo Info: \(photoInfo)")
//                if let photoData = FlickrClient.sharedInstance().makeImageDataFrom1(photo: photoInfo[indexPath.item]) {
//                    cell.locationPhoto.image = UIImage(data: photoData)
//                    activityIndicator.stopAnimating()
//                    cell.locationPhoto.alpha = 1.0
//                }
                DispatchQueue.global().async {
                    self.downloadSinglePhoto(photo: photoInfo[indexPath.item], { (imageDataForCell) in
                        guard let image = imageDataForCell else {
                            print("single photo image error")
                            return
                        }
                        
                        if let imageForCell = UIImage(data: image) {
                            DispatchQueue.main.async {
                                cell.locationPhoto.image = imageForCell
                                cell.locationPhoto.alpha = 1.0
                                activityIndicator.stopAnimating()
                            }
                        }
                    })
                }
            }
        }

        return cell
    }
    
    func downloadSinglePhoto(photo: FlickrClient.Photo, _ completionForSingleDownload: (_ imageData: Data?) -> Void) {
        if let photoData = FlickrClient.sharedInstance().makeImageDataFrom1(photo: photo) {
            completionForSingleDownload(photoData)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //print("DL Photo info: \(downloadedPhotos[indexPath.item])")
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        //print("CD Photo info: \(photoToDelete.image!)")
        
        //downloadedPhotos.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
        
        dataController.viewContext.delete(photoToDelete)
        
        savePhotos()
        performFetch()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
}

