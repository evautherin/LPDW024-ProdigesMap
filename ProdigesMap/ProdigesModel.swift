//
//  ProdigesModel.swift
//  ProdigesMap
//
//  Created by Etienne Vautherin on 31/01/2024.
//

import Foundation
import CoreLocation
import SwiftUI

@Observable
class ProdigesModel : NSObject {
    var name = "User"

    static let shared = ProdigesModel()
    let center = CLLocationCoordinate2D(latitude: 48.9355351, longitude: 2.3030026)
    private let manager = CLLocationManager()

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
                
                let identifiers = await monitor.identifiers
//                for identifier in identifiers {
//                    print("Condition: \(identifier)")
//                }
                identifiers.forEach { print("Condition: \($0)") }
                
                let events = await monitor.events
                let stateStrings = events.map { event in
                    return switch event.state {
                    case .unknown: "unknown"
                    case .satisfied: "satisfied"
                    case .unsatisfied: "unsatisfied"
                    case .unmonitored: "unmonitored"
                    @unknown default: "unknown default"
                    }
                }
                for try await stateString in stateStrings {
                    name = stateString
                }
//                for try await event in events {
//                    print("state:\(event.state), id:\(event.identifier), date:\(event.date)")
//                    switch event.state {
//                        
//                    case .unknown:
//                        name = "unknown"
//                        
//                    case .satisfied:
//                        name = "satisfied"
//
//                    case .unsatisfied:
//                        name = "unsatisfied"
//
//                    case .unmonitored:
//                        name = "unmonitored"
//
//                    @unknown default:
//                        name = "unknown default"
//
//                    }
//                }
            }
        }
    }

}
