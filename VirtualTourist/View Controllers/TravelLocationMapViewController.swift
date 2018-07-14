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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        setupFetchedResultsController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    fileprivate func loadPins() {
        if let fetchedObjects = fetchedResultsController.fetchedObjects {
            print("total objects with ID: \(String(describing: fetchedObjects.count))")
            //print("fetched objects: \(fetchedObjects)")
            
            
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
            print("coordinate: \(coordinate)")
            
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
        print("annotation coordinate: \(view.annotation!.coordinate)")
        if checkForMatching(coordinate: view.annotation!.coordinate) {
            self.performSegue(withIdentifier: "showPhotoAlbum", sender: self)
        } else {
            print("can't segue")
            return
        }
    }
    
    //check selected annotation's coordinate, and compare to fetched objects
    func checkForMatching(coordinate: CLLocationCoordinate2D) -> Bool {
        if let savedPins = fetchedResultsController.fetchedObjects {
            for pin in savedPins {
                print("pin lat: \(pin.latitude)\npin lon: \(pin.longitude)")
                print("coordinate lat: \(coordinate.latitude)\ncoordinate lon: \(coordinate.longitude)")
                if pin.latitude == coordinate.latitude && pin.longitude == coordinate.longitude{
                    print("numbers match! PinID: \(pin.objectID)")
                    self.objectID = pin.objectID
                    return true
                } else {
                    print("numbers don't match")
                }
            }
        }
        return false
    }
    
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("region changed")
        print("mapView.region: \(mapView.region)")
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
        }
    }
}

