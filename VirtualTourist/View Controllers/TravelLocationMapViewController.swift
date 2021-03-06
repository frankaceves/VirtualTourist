//
//  ViewController.swift
//  CoreDataTest
//
//  Created by Frank Anthony Aceves on 6/10/18.
//  Copyright © 2018 Frank Aceves. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var gestureRecognizer: UILongPressGestureRecognizer!
    
    var pin: Pin!
    var objectID: NSManagedObjectID!
    var objectToPass: NSManagedObject!
    var dataController: DataController!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        configureMapView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    fileprivate func loadPins() {
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            
            var annotations = [MKPointAnnotation]()
            
            //iterate through fetchedObjects
            for object in fetchedObjects {
                
                //gather lat & lon to create coordinates
                let lat = CLLocationDegrees(object.latitude)
                let long = CLLocationDegrees(object.longitude)
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                //create annotation
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                annotations.append(annotation)
            }
            
            //add annotation to map
            self.mapView.addAnnotations(annotations)
        }
    }

    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
       self.loadPins()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getTouchLocation(_ sender: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self.mapView)
            let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
            
            //add map annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            //add annotation to map
            self.mapView.addAnnotation(annotation)
            
            //save pin and coordinate
            addPin(coordinate: coordinate)
        }
    }
    
    func addPin(coordinate: CLLocationCoordinate2D) {
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.id = String(arc4random())
        try! dataController.viewContext.save()
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        
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
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if checkForMatching(coordinate: view.annotation!.coordinate) {
            self.performSegue(withIdentifier: "showPhotoAlbum", sender: self)
        } else {
            print("can't segue")
            return
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //print("region changed\nCurrentRegion: \(mapView.region)\nSpan: \(mapView.region.span)\nCenter: \(mapView.region.center)")
        let mapData = ["lat":mapView.region.span.latitudeDelta, "lon":mapView.region.span.longitudeDelta, "centerLat":mapView.region.center.latitude, "centerLon":mapView.region.center.longitude] as [String : Any]
        
        defaults.set(mapData, forKey: "mapZoom")
    }
    
    //check selected annotation's coordinate, and compare to fetched objects
    private func checkForMatching(coordinate: CLLocationCoordinate2D) -> Bool {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed to match pin location data: \(error.localizedDescription)")
        }
        
        if let savedPins = fetchedResultsController.fetchedObjects {
            for pin in savedPins {
                
                if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude{
                    self.pin = pin
                    return true
                } else {
                    //print("numbers don't match")
                }
            }
        }
        return false
    }
    
    private func configureMapView() {
        if let settings = defaults.dictionary(forKey: "mapZoom") {
            print("success: \(settings)")
            let span = MKCoordinateSpan(latitudeDelta: settings["lat"] as! CLLocationDegrees, longitudeDelta: settings["lon"] as! CLLocationDegrees)
            let center = CLLocationCoordinate2D(latitude: settings["centerLat"] as! CLLocationDegrees, longitude: settings["centerLon"] as! CLLocationDegrees)
            
            let region = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // MARK: - NAVIGATION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhotoAlbum" {
            //send lat & long to new VC
            let vc = segue.destination as? PhotoAlbumViewController
            let coordinate = self.mapView.selectedAnnotations[0].coordinate

            vc?.currentCoordinate = coordinate
            vc?.dataController = dataController
            vc?.objectID = self.objectID
            vc?.pin = self.pin
        }
    }
}

