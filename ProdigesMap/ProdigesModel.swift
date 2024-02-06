//
//  ProdigesModel.swift
//  ProdigesMap
//
//  Created by Etienne Vautherin on 31/01/2024.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine
import AsyncAlgorithms
import AsyncExtensions
import FirebaseFirestore

@Observable
class ProdigesModel : NSObject {
    var prodiges = [Prodige]()
    var trackedProdiges: [Prodige] {
//        prodiges.filter { $0.tracked }
        prodiges.filter(\.tracked)
    }
    var currentProdige: Prodige?
    var conditionDisplay = ""
    var initialEvent: CLMonitor.Event?

    static let shared = ProdigesModel()
    let center = CLLocationCoordinate2D(latitude: 48.9355351, longitude: 2.3030026)
    private let manager = CLLocationManager()

    override init() {
        super.init()
        
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        
        Task {
            let db = Firestore.firestore()
            let collection = db.collection("Prodiges")

            for await currentID in UserDefaults.standard.observeKey(at: \.currentProdige) {
                switch currentID {
                case .none: print("No current user")
                case .some(let currentID):
                    let documentRef = collection.document(currentID)
                    currentProdige = try? await documentRef.getDocument(as: Prodige.self)
                }
            }
        }
        
        trackProdiges()
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
                for identifier in identifiers {
                    if let record = await monitor.record(for: identifier) {
                        initialEvent = record.lastEvent
                    }
                }
//                identifiers.forEach {
//                    print("Condition: \(await monitor.record(for: $0).debugDescription)")
//                }
                
                let events = await monitor.events
                
                let allEvents = switch initialEvent {
                case .some(let initialEvent): chain(AsyncJustSequence(initialEvent), events).eraseToAnyAsyncSequence()
                case .none: events.eraseToAnyAsyncSequence()
                }
                
                let stateStrings = allEvents
                    .map { event in
                    return switch event.state {
                    case .unknown: "unknown"
                    case .satisfied: "satisfied"
                    case .unsatisfied: "unsatisfied"
                    case .unmonitored: "unmonitored"
                    @unknown default: "unknown default"
                    }
                }
                for try await stateString in stateStrings {
                    conditionDisplay = stateString
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

extension ProdigesModel {
    func trackProdiges() {
        let db = Firestore.firestore()
        db.collection("Prodiges") // .whereField("tracked", isEqualTo: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                do {
                    self.prodiges = try documents.compactMap { try $0.data(as: Prodige.self) }
                } catch {
                    print("Error deserializing documents: \(error)")
                }
                print("Tracked Prodiges: \(self.prodiges)")
            }
    }
}


extension UserDefaults {
    @objc dynamic var currentProdige: String? { string(forKey: "CurrentProdige") }

    typealias AsyncValues<T> = AsyncPublisher<AnyPublisher<T, Never>>
    func observeKey<T>(at path: KeyPath<UserDefaults, T>) -> AsyncValues<T> {
        return self.publisher(for: path, options: [.initial, .new])
            .eraseToAnyPublisher()
            .values
    }
}
