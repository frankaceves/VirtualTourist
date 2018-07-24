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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.dataSource = self
        collectionView.delegate = self
        configMap()
        // Do any additional setup after loading the view.
        print("view Did Load")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view WIll Appear")
        print("dl Photo array: \(downloadedPhotos)")
        //location = getObjectFromPassed(id: objectID)
        print("the pin that was passed: \(pin!)")
        print("passed pin photos: \(String(describing: pin.photos?.count))")
        
        //move getPhotos to Fetch?  If fetchedObjects <= 0, get photos, else loadPhotos (need to create that func)
        //getPhotos(lat: currentCoordinate.latitude, lon: currentCoordinate.longitude)
        
        downloadPhotosOrFetchPhotos()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("view WILL disappear.")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("view DID disappear")
        savePhotos()
        fetchedResultsController = nil
        downloadedPhotos = []
        print("dl photo after disappear: \(downloadedPhotos)")
        FlickrClient.sharedInstance().clearPhotoResults()
    }
    
    fileprivate func downloadPhotos() {
        // DOWNLOAD PHOTOS
        getPhotos(lat: pin.latitude, lon: pin.longitude, completionHandlerfForGetPhotos: { (success, error) in
            if success == true {
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            } else {
                print("error in getPhotos via downloadPhotos method: \(error!)")
            }
        })
    }
    
    func downloadPhotosOrFetchPhotos() {
        
        if let photoCount = pin.photos?.count {
            if photoCount <= 0 {
                downloadPhotos()
            } else {
                //FETCH PHOTOS
                print("load fetched photos")
                fetchPhotos()
            }
        } else {
            print("there are no photos to load.")
        }
    }
    
    func fetchPhotos() {
        setupFetchedResultsController()
        
        // testing Fetch
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            print("fetched Objects count: \(fetchedObjects.count)")
            for photo in fetchedObjects {
                if let imageData = photo.image {
                    downloadedPhotos.append(imageData)
                }
            }
        }
        collectionView.reloadData()
    }
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate: NSPredicate?
        
        predicate = NSPredicate(format: "location == %@", pin)
        fetchRequest.predicate = predicate
        
        
        let sortDescriptor = NSSortDescriptor(key: "image", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        print("fetchRequest: \(fetchRequest)")
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
    func getPhotos(lat: Double, lon: Double, completionHandlerfForGetPhotos: @escaping (_ success: Bool, _ error: String?) -> Void) {
        FlickrClient.sharedInstance().downloadPhotosForLocation(lat: lat, lon: lon) { (images, error) in
            if error != nil {
                completionHandlerfForGetPhotos(false, "error downloading images: \(error!)")
            }
            
            guard let images = images else {
                completionHandlerfForGetPhotos(false, "no images returned")
                return
            }
            
            for image in images {
                let photo = Photo(context: self.dataController.viewContext)
                
                //clear attributes?
                photo.image = image
                photo.location = self.pin
                print("photoInfo: \(photo)")
                
                self.downloadedPhotos.append(image)
                // ***can't save core data here***
                
            }
            
            completionHandlerfForGetPhotos(true, nil)
        }
        
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
        }
    }
    
    // MARK: - COLLECTION VIEW
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("***Collection View: Number of items in section***")
        return downloadedPhotos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //print("***Collection View: Cell For Row at Index Path***")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! LocationImageCollectionViewCell
        
        
        let fetchedPhoto = downloadedPhotos[indexPath.item]
        
        cell.locationPhoto.image = UIImage(data: fetchedPhoto)
        
        return cell
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

