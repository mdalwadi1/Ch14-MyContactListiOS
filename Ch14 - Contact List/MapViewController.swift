//
//  MapViewController.swift
//  Ch14 - Contact List
//
//  Created by user216619 on 9/19/22.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var sgmtMapType: UISegmentedControl!
    
    var locationManager: CLLocationManager!
    var contacts:[Contact] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        mapView.delegate = self
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }

    @IBAction func mapTypeChanged(_ sender: Any) {
        switch sgmtMapType.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .hybrid
        case 2:
            mapView.mapType = .satellite
        default: break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //Get contacts from Core Data
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "Contact")
        var fetchedObjects:[NSManagedObject] = []
        do {
            fetchedObjects = try context.fetch(request)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        contacts = fetchedObjects as! [Contact]
        
        //remove all annotations
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        //go through all contacts
        for contact in contacts { //as! [Contact] {
            let address = "\(contact.streetAddress!), \(contact.city!) \(contact.state!)"
            
            //geocoding
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString(address) {
                (placemarks, error) in
                self.processAddressResponse(contact, withPlacemarks: placemarks, error: error)
            }
        }
    }
    
    private func processAddressResponse(_ contact: Contact, withPlacemarks placemarks: [CLPlacemark]?,error: Error?) {
        if let error = error {
            print("Geocode Error: \(error)")
        }
        else {
            var bestMatch: CLLocation?
            if let placemarks = placemarks, placemarks.count > 0 {
                bestMatch = placemarks.first?.location
            }
            if let coordinate = bestMatch?.coordinate {
                let mp = MapPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                mp.title = contact.contactName
                mp.subtitle = contact.streetAddress
                mapView.addAnnotation(mp)
            }
            else {
                print("Didn't find any matching locations")
            }
        }
    }

    @IBAction func findUser(_ sender: Any) {
        //mapView.showsUserLocation = true
        //mapView.setUserTrackingMode(.follow, animated: true)
        mapView.showAnnotations(mapView.annotations, animated: true)
    }
 
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        var span = MKCoordinateSpan()
        span.latitudeDelta = 0.05
        span.longitudeDelta = 0.05
        let viewRegion = MKCoordinateRegion(center: userLocation.coordinate, span: span)
        mapView.setRegion(viewRegion, animated: true)
        //mapView.removeAnnotations(self.mapView.annotations)
        let mp = MapPoint(latitude: userLocation.coordinate.latitude,
                          longitude: userLocation.coordinate.longitude)
        mp.title = "You"
        mp.subtitle = "Are here"
        mapView.addAnnotation(mp)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
