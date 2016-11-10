//
//  LocationServices.swift
//  Magnet
//
//  Created by Francisco Jordano on 17/10/2016.
//

import Foundation
import CoreLocation
import SwiftyJSON

class ScannerGeolocation: NSObject, CLLocationManagerDelegate, Scanner {
  let locationManager: CLLocationManager = CLLocationManager()
  var callback: ((Dictionary<String, AnyObject>) -> Void)!
  var initialized: Bool = false
  var bestEffort: CLLocation!
  let MIN_DISTANCE: Double = 10
  
  init(callback: (Dictionary<String, AnyObject>) -> Void) {
    super.init()
    self.callback = callback
  }
  
  func start() {
    startLocationManager()
  }
  
  func stop() {
    NSObject.cancelPreviousPerformRequestsWithTarget(self)
    locationManager.stopUpdatingLocation()
  }
  
  func startLocationManager() -> Bool {
    NSLog("MagnetScanner :: Starting geolocation scanner")
    guard CLLocationManager.locationServicesEnabled() else {
      NSLog("MagnetScanner :: Location Services not enabled")
      return false
    }
    
    guard initialized == false else {
      locationManager.startUpdatingLocation()
      return true
    }
    
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    locationManager.distanceFilter = 5
    locationManager.headingFilter = 5
    locationManager.requestWhenInUseAuthorization()
    
    locationManager.startUpdatingLocation()
    initialized  = true;
    
    return true;
  }
  
  // Deletegate methods
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard locations.count > 0 else {
        return
    }
    
    guard let location: CLLocation = locations.last else {
        return
    }
    
    guard location.horizontalAccuracy >= 0 else {
        return
    }
    
    guard bestEffort == nil || bestEffort!.horizontalAccuracy > location.horizontalAccuracy else {
        return
    }
    
    bestEffort = location
    
    guard location.horizontalAccuracy <= self.locationManager.desiredAccuracy else {
        NSLog("MagnetScanner :: Discarding location \(location) because accuracy \(location.horizontalAccuracy) is \(self.locationManager.desiredAccuracy)")
        return;
    }
    
    NSLog("MagnetScanner :: Got location \(location)")
    let lat: CLLocationDegrees = location.coordinate.latitude
    let lon: CLLocationDegrees = location.coordinate.longitude
    
    stop()
    
    NSLog("MagnetScanner :: Got location update \(lat),\(lon)")
    
    // Here is where we call to the magnet service and then update the callback
    NetworkResolver.resolveLocation(lat, lon: lon, callback: {(result: Array<JSON>) in
        result.forEach({ (json) in
            let url = json["url"].string
            let channel = json["channel_id"].string
            let magnetItem: Dictionary<String, AnyObject> = ["url": url!, "channel_id": channel!]
            NSLog("MagnetScanner :: Found item \(magnetItem)")
            self.callback(magnetItem)
        })
    })
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    NSLog("MagnetScanner :: Got error during location \(error)")
    stop()
  }
}
