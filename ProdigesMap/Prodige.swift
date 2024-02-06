//
//  Prodige.swift
//  ProdigesMap
//
//  Created by Etienne Vautherin on 02/02/2024.
//

import Foundation
import FirebaseFirestore

struct Prodige : Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let password: String
    let position: GeoPoint
    let tracked: Bool
}
