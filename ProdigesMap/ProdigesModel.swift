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
import UserNotifications

@Observable
class ProdigesModel : NSObject {
    static let shared = ProdigesModel()

    var prodiges = [Prodige]()
    var currentProdige: Prodige?
    var locationUpdateDisplay = ""


    let center = CLLocationCoordinate2D(latitude: 48.9355351, longitude: 2.3030026)
    private let manager = CLLocationManager()
    private let prodigesCollection = Firestore.firestore().collection("Prodiges")

    private var currentProdigeListener: ListenerRegistration?
    @ObservationIgnored private var currentId: String? {
        didSet {
            listenCurrentProdige()
            monitorCurrentId()
        }
    }
    
    private var monitorCurrentIdTask: Task<(), Error>?
    @ObservationIgnored private var monitor: CLMonitor? {
        didSet {
            monitorCurrentId()
        }
    }
    
    private var locationUpdateTask: Task<(), Error>?
    private var notificationAuthorized = false

    override init() {
        super.init()
        
        initNotifications()
        
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        
        initCurrentId()
        listenProdiges()
    }
    
    func setCurrentId(currentId: String?) {
        self.currentId = currentId
        if let currentId {
            UserDefaults.standard.set(currentId, forKey: "currentId")
        } else {
            UserDefaults.standard.removeObject(forKey: "currentId")
        }
    }
    
    func initCurrentId() {
        self.currentId = UserDefaults.standard.string(forKey: "currentId")
    }
}

// MARK: Core Location
extension ProdigesModel : CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        print("\(manager.authorizationStatus)")
        if [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) {
            if let _ = monitor { return }
            
            Task {
                let monitor = await CLMonitor("monitorName")
                let condition = CLMonitor.CircularGeographicCondition(
                    center: center,
                    radius: 2000.0
                )
                await monitor.add(condition, identifier: "Condition")
                self.monitor = monitor
            }
        }
    }

    func monitorCurrentId() {
        monitorCurrentIdTask?.cancel()
        monitorCurrentIdTask = .none
        
        guard let monitor, let currentId else { return }

        monitorCurrentIdTask = Task {
            var initialEvent: CLMonitor.Event?

            let identifiers = await monitor.identifiers
            for identifier in identifiers {
                if let record = await monitor.record(for: identifier) {
                    initialEvent = record.lastEvent
                }
            }
            
            let futureEvents = await monitor.events
            
            let allEvents = switch initialEvent {
            case .some(let initialEvent): chain(AsyncJustSequence(initialEvent), futureEvents).eraseToAnyAsyncSequence()
            case .none: futureEvents.eraseToAnyAsyncSequence()
            }

            for try await event in allEvents {
                let tracked = switch event.state {
                case .satisfied: true
                default: false
                }
                updateProdige(id: currentId, values: ["tracked": tracked])
                tracked ? startLocationUpdates() : stopLocationUpdates()
            }
        }
    }
    
    func startLocationUpdates() {
        displayStartUpdateNotification()
        locationUpdateTask = Task {
            defer { print("*** End update task") }
            
            print("*** Start update task")
            let updates = CLLocationUpdate.liveUpdates()
            for try await update in updates {
                guard let currentId else { continue }
                
                if let location = update.location {
                    print(location)
                    let position = GeoPoint(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude
                    )
                    updateProdige(id: currentId, values: ["position": position])
                }
            }
        }
    }
    
    func stopLocationUpdates() {
        displayStopUpdateNotification()
        locationUpdateTask?.cancel()
        locationUpdateTask = .none
    }
}

// MARK: FireBase synchronization
extension ProdigesModel {
    func listenProdiges() {
        prodigesCollection // .whereField("tracked", isEqualTo: true)
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
    
    func listenCurrentProdige() {
        currentProdigeListener?.remove()
        currentProdigeListener = .none

        guard let currentId else {
            self.currentProdige = .none
            return
        }
        
        currentProdigeListener = prodigesCollection.document(currentId).addSnapshotListener { document, error in
            let prodige = try? document?.data(as: Prodige.self)
            self.currentProdige = prodige
            print("*** Current Prodige is now: \(String(describing: prodige))")
        }
    }

    func updateProdige(id: String, values: [AnyHashable: Any]) {
        prodigesCollection.document(id).updateData(values)
    }
    
    func registerNewProdige(name: String, password: String) async {
        let position = GeoPoint(latitude: 0, longitude: 0)
        do {
            let ref = try await ProdigesModel.shared.prodigesCollection.addDocument(data: [
                "name": name,
                "password": password,
                "position": position,
                "tracked": false
            ])
            print("Document added with ID: \(ref.documentID)")
            setCurrentId(currentId: ref.documentID)
        } catch {
            print("Error adding document: \(error.localizedDescription)")
        }
    }
}

// MARK: Notifications
extension ProdigesModel {
    enum Notification {
        case localisationUpdateStarted
        case localisationUpdateStopped
        
        var identifier: String {
            switch self {
            case .localisationUpdateStarted: "localisationUpdateStarted"
            case .localisationUpdateStopped: "localisationUpdateStopped"
            }
        }
        var title: String {
            "Localisation"
        }
        var body: String {
            switch self {
            case .localisationUpdateStarted:
                "Votre position est actuellement utilisée parce que vous êtes autour de la Fac."
            case .localisationUpdateStopped:
                "Votre position n'est plus utilisée parce que vous êtes éloigné de la Fac."
            }
        }
    }
    
    func initNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { result, error in
            self.notificationAuthorized = result
        }
    }
    
    func displayStartUpdateNotification() {
        plainUpdateNotification(.localisationUpdateStarted)
    }
    
    func displayStopUpdateNotification() {
        plainUpdateNotification(.localisationUpdateStopped)

    }
    
    private func plainUpdateNotification(_ notification: Notification) {
        locationUpdateDisplay = notification.body
        
        Task {
            repeat {} while !notificationAuthorized
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = notification.title
            content.body = notification.body
            let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
            let _ = try await UNUserNotificationCenter.current().add(request)
        }
    }
}


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
