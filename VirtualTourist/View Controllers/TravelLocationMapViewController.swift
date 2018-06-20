//
//  ViewController.swift
//  CoreDataTest
//
//  Created by Frank Anthony Aceves on 6/10/18.
//  Copyright © 2018 Frank Aceves. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationMapViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet var mapView: MKMapView!
    
    @IBOutlet var gestureRecognizer: UILongPressGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
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
        }
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            //pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.red
            pinView?.animatesDrop = true
            
            
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

}

