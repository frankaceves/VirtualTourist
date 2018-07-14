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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    var dataController: DataController!
    
    //the location whose photos are being displayed
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
    var downloadedPhotos = [Data]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.dataSource = self
        configMap()
        //setupFetchedResultsController()
        // Do any additional setup after loading the view.
        print("view Did Load")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("view WIll Appear")
        pin = getObjectFromPassed(id: objectID) as! Pin
        print("pinInfo: \(pin!)")
        
        getPhotos(lat: currentCoordinate.latitude, lon: currentCoordinate.longitude)
        //setupFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("view will disappear")
        savePhotos()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func getObjectFromPassed(id: NSManagedObjectID) -> NSManagedObject {
        var location = NSManagedObject()
        do {
            location = try dataController.viewContext.existingObject(with: objectID)
        } catch {
            print("could not get object: \(error.localizedDescription)")
        }
        print("managedObject: \(location)")
        print("managedObject photos: \(location.objectIDs(forRelationshipNamed: "photos"))")
        return location
    }
    
    func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        //let id = objectID
        let predicate: NSPredicate?
        
//        predicate = NSPredicate(format: "latitude BEGINSWITH %@ AND longitude BEGINSWITH %@", newLatitude as CVarArg, newLongitude as CVarArg)
        predicate = NSPredicate(format: "location == %@", pin)
        fetchRequest.predicate = predicate
        
        
        //let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        let sortDescriptor = NSSortDescriptor()
        fetchRequest.sortDescriptors = [sortDescriptor]
        print("fetchRequest: \(fetchRequest)")
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        // testing Fetch
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            print("fetched Objects: \(fetchedObjects)")
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
    func getPhotos(lat: Double, lon: Double) {
        FlickrClient.sharedInstance().downloadPhotosForLocation(lat: lat, lon: lon) { (images, error) in
            if error != nil {
                print("error creating images: \(error!)")
            }
            
            guard let images = images else {
                print("no images returned")
                return
            }
            
            for image in images {
                let photo = Photo(context: self.dataController.viewContext)
                photo.image = image
                photo.location = self.pin
                //photo.location?.latitude = self.pin.latitude
                //photo.location?.longitude = self.pin.longitude
                print("photoInfo: \(photo)")
                self.downloadedPhotos.append(image)
            }

            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
        
    }
    
    // MARK: - PERSIST PHOTOS
    
    func savePhotos() {
        if dataController.viewContext.hasChanges {
            do {
                try dataController.viewContext.save()
            } catch {
                print("an error occurred while saving: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - COLLECTION VIEW
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("downloadedPhotos Count: \(downloadedPhotos.count)")
        return downloadedPhotos.count
        //fetchedResultsController.fetchedObjects
        //print("fetchedObjects: \(fetchedResultsController.fetchedObjects?.count ?? 3)")
        //return fetchedResultsController.fetchedObjects?.count ?? 3
        //return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! LocationImageCollectionViewCell
        let photo = self.downloadedPhotos[indexPath.item]
        
        cell.locationPhoto.image = UIImage(data: photo)
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
