//
//  AddUserView.swift
//  ProdigesMap
//
//  Created by Etienne Vautherin on 05/02/2024.
//

import SwiftUI

struct LoginView: View {

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack {
                TextField("Nom", text: $name)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                SecureField("Mot de passe", text: $password)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button("Se connecter") {
                    // Logique ici
                }
                .padding()
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .navigationTitle("Connectez-vous")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}


#Preview {
    LoginView()
}
