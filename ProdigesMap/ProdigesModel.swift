//
//  ProdigesModel.swift
//  ProdigesMap
//
//  Created by Etienne Vautherin on 31/01/2024.
//

import Foundation
import CoreLocation

class ProdigesModel : NSObject {
    static let shared = ProdigesModel()
    let center = CLLocationCoordinate2D(latitude: 48.9355351, longitude: 2.3030026)
    private let manager = CLLocationManager()
//    var monitor: CLMonitor!
    
    override init() {
        super.init()
        
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }
    
}


extension ProdigesModel : CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("\(manager.authorizationStatus)")
        if manager.authorizationStatus == .authorizedWhenInUse {
            Task {
                let monitor = await CLMonitor("monitorName")
                let condition = CLMonitor.CircularGeographicCondition(
                    center: center,
                    radius: 2000.0
                )
                await monitor.add(condition, identifier: "Condition")
                
                for identifier in await monitor.identifiers {
                    print("Condition: \(identifier)")
                }
                
                let events = await monitor.events
                for try await event in events {
                    print("state:\(event.state), id:\(event.identifier), date:\(event.date)")
                }
            }
        }
    }

}
