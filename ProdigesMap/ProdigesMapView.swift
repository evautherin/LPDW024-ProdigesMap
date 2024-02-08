//
//  ProdigesMapView.swift
//  ProdigesMap
//
//  Created by Etienne Vautherin on 31/01/2024.
//

import SwiftUI
import CoreLocation
import MapKit


struct ProdigesMapView: View {
    let model = ProdigesModel.shared
    @State private var newUserPresented = false
    @State var position: MKCoordinateRegion
    
    init() {
        position = MKCoordinateRegion(
            center: model.center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }

    var body: some View {
        ZStack {
            Map(initialPosition: MapCameraPosition.region(position)) {
                ForEach(model.prodiges.filter(\.tracked)) { trackedProdige in
                    let location = CLLocationCoordinate2D(
                        latitude: trackedProdige.position.latitude,
                        longitude: trackedProdige.position.longitude
                    )
                    Marker(trackedProdige.name, systemImage: "person.circle", coordinate: location)
                }
            }
            VStack {
                if let currentProdige = model.currentProdige {
                    HStack {
                        Text(currentProdige.name)
                            .font(.largeTitle)
                            .underline()
                            .bold()
                            .padding(.leading)
                        Button("Start updates") {
                            model.startLocationUpdates()
                        }
                        Spacer()
                    }
                }
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        newUserPresented.toggle()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .padding(.trailing)
                            .padding(.top)
                    }
                }
                Text(model.locationUpdateDisplay)
            }
        }
        .sheet(isPresented: $newUserPresented) {
            LoginView()
        }
    }
}

#Preview {
    ProdigesMapView()
}
