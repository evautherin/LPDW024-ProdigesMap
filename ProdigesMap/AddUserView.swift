//
//  AddUserView.swift
//  ProdigesMap
//
//  Created by Etienne Vautherin on 05/02/2024.
//

import SwiftUI

struct AddUserView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Button("Press to dismiss") {
            dismiss()
        }
    }
}

#Preview {
    AddUserView()
}
