//
//  AddUserView.swift
//  ProdigesMap
//
//  Created by Etienne Vautherin on 05/02/2024.
//

import SwiftUI

struct LoginView: View {
    let model = ProdigesModel.shared

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
                    let foundProdige = model.prodiges
//                        .filter { $0.name == name }
                        .first(where: { $0.name == name })
                    
                    switch foundProdige {
                    case .none:
                        // S'enregistrer
                        print("*** S'enregistrer")
                        break
                        
                    case .some(let foundProdige):
                        if foundProdige.password == password {
                            // J'ai le bon prodige
                            print("*** J'ai le bon prodige")
                        } else {
                            // Le password est mauvais
                            print("*** Le password est mauvais")
                        }
                    }
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
