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
    var currentListener: ListenerRegistration?
    @ObservationIgnored var currentId: String? {
        didSet {
            if let listener = currentListener {
                listener.remove()
            }
            guard let currentId = currentId else { return }
            
            currentListener = prodigesCollection.document(currentId).addSnapshotListener { querySnapshot, error in
                let prodige = try? querySnapshot?.data(as: Prodige.self)
                self.currentProdige = prodige
                print("*** Current Prodige: \(String(describing: prodige))")
//                guard let document = querySnapshot?. else {
//                    print("Error fetching documents: \(error!)")
//                    return
//                }
//                do {
//                    let currentProdiges = try documents.compactMap { try $0.data(as: Prodige.self) }
//                    let currentProdige = currentProdiges.first
//                    print("*** Current Prodige: \(String(describing: currentProdige))")
//                    self.currentProdige = currentProdige
//                } catch {
//                    print("Error deserializing documents: \(error)")
//                }
                
            }

        }
    }
    var currentProdige: Prodige?
    var conditionDisplay = ""
    var initialEvent: CLMonitor.Event?

    static let shared = ProdigesModel()
    let center = CLLocationCoordinate2D(latitude: 48.9355351, longitude: 2.3030026)
    private let manager = CLLocationManager()
    let prodigesCollection = Firestore.firestore().collection("Prodiges")

    override init() {
        super.init()
        
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        
//        Task {
//            var currentListener: ListenerRegistration?
//            for await currentId in UserDefaults.standard.observeKey(at: \.currentProdige) {
//                switch currentId {
//                case .none: print("No current one!")
//                case .some(let currentID):
//                    if let listener = currentListener {
//                        listener.remove()
//                        currentListener = nil
//                    }
//                    currentListener = prodigesCollection.whereField("id", isEqualTo: currentID).addSnapshotListener { querySnapshot, error in
//                        guard let documents = querySnapshot?.documents else {
//                            print("Error fetching documents: \(error!)")
//                            return
//                        }
//                        do {
//                            let currentProdige = try documents.compactMap { try $0.data(as: Prodige.self) }.first
//                            print("*** Current Prodige: \(String(describing: currentProdige))")
//                            self.currentProdige = currentProdige
//                        } catch {
//                            print("Error deserializing documents: \(error)")
//                        }
//                        
//                    }
//                }
//            }
//        }
        
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
    
    func locationUpdates() {
            Task {
                let updates = CLLocationUpdate.liveUpdates()
                for try await update in updates {
                    if let loggedInProdigeId = currentProdige?.id {
                        if let location = update.location {
                            print(location)
                            let position = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                            updateProdige(id: loggedInProdigeId, values: ["position": position])
                        }
                    }
                }
            }
        }
        
        func updateProdige(id: String, values: [AnyHashable: Any]) {
            prodigesCollection.document(id).updateData(values)
        }}


//extension UserDefaults {
//    @objc dynamic var currentProdige: String? {
//        let value = string(forKey: "CurrentProdige")
//        print("*** value: \(String(describing: value))")
//        return value
//    }
//
//    typealias AsyncValues<T> = AsyncPublisher<AnyPublisher<T, Never>>
//    func observeKey<T>(at path: KeyPath<UserDefaults, T>) -> AsyncValues<T> {
//        return self.publisher(for: path, options: [.initial, .new])
//            .print("*** observeKey")
//            .eraseToAnyPublisher()
//            .values
//    }
//
//    func setId(_ id: String, forKey key: String) {
//        set(id, forKey: key)
//        let value = UserDefaults.standard.string(forKey: key)
//        print("*** \(key): \(String(describing: value))")
////        if let encoded = try? JSONEncoder().encode(id) {
////            set(encoded, forKey: key)
////        }
//    }
//
////    func getId(forKey key: String) -> String? {
////        if let data = data(forKey: key),
////           let id = try? JSONDecoder().decode(String.self, from: data) {
////            return id
////        }
////        return nil
////    }
//}
