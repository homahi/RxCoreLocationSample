//
//  ViewController.swift
//  CoreSample
//
//  Created by 原野誉大 on 2018/02/27.
//  Copyright © 2018年 原野誉大. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import RxSwift
import RxCoreMotion
import RxCoreLocation
import RxCocoa

class ViewController: UIViewController {

    let locationManager = CLLocationManager()
    let pedometer = CMPedometer()
    let disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        let locationObservable = locationManager.rx.didUpdateLocations.map { (manager, locations) -> GPS in
            let lastLocation = locations.last
            let gps = GPS(ts: Date(), lat: (lastLocation?.coordinate.latitude)!, lon: (lastLocation?.coordinate.longitude)!, alt: (lastLocation?.altitude)!, acc: (lastLocation?.verticalAccuracy)!)
            return gps
            }.buffer(timeSpan: 3, count:100,scheduler: MainScheduler.instance)

        let batteryObservable = Observable<Int>.interval(3.0, scheduler: MainScheduler.instance).map({ _ -> Battery in
            return Battery(ts: Date(), level: UIDevice.current.batteryLevel * 100)
        }).buffer(timeSpan: 3, count:100,scheduler: MainScheduler.instance)

        Observable<Int>.interval(1, scheduler: MainScheduler.instance)
            .map({ _ in 1})
            .subscribe{
                self.locationManager.requestLocation()
        }.disposed(by: disposeBag)
        
        // CoreMotionのStreamを作る
        
        let pedometerObservable = pedometer.rx.pedometer(from: Date()).debug("pedometer")

        Observable.zip(locationObservable, batteryObservable ).debug("zip")
            .subscribe(onNext: { _ in
        }).disposed(by: disposeBag)
        
        // それらを一定間隔で固めて送信するStreamを作る
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }


}

struct GPS: Decodable {
    var ts: Date
    var lat: CLLocationDegrees
    var lon: CLLocationDegrees
    var alt: CLLocationDegrees
    var acc: Double
}
struct Battery : Decodable{
    var ts: Date
    var level: Float
}
