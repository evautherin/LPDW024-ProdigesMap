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
    @State private var badName = false
    @State private var badPassword = false
    
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
                    //                        .first(where: { $0.name == name })
                        .first { $0.name == name }
                    
                    switch foundProdige {
                    case .none:
                        // S'enregistrer
                        print("*** S'enregistrer")
                        badName = true
                        
                    case .some(let foundProdige):
                        if foundProdige.password == password {
                            // J'ai le bon prodige
                            print("*** J'ai le bon prodige")
                            model.setCurrentId(currentId: foundProdige.id)
                            dismiss()
                        } else {
                            // Le password est mauvais
                            print("*** Le password est mauvais")
                            badPassword = true
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
            .alert(
                "Nom introuvable...",
                isPresented: $badName,
                actions: {
                    Button("Oui") {
                        // Il faut créer le nouvel utilisateur + s'enregistrer avec !
                        Task {
                            await model.registerNewProdige(name: name, password: password)
                            badName = false
                        }
                        dismiss()
                    }
                    Button("Non") {
                        badName = false
                    }
                },
                message: {
                    Text("Le nom que vous avez entré n'a pas été trouvé. Souhaitez-vous créer un nouvel identifiant ?")
                }
            )
            .alert(
                "Mauvais mot de passe !",
                isPresented: $badPassword,
                actions: {
                    Button("Ok") {
                        badPassword = false
                    }
                },
                message: {
                    Text("Le mot de passe que vous avez entré n'est pas bon ! Veuillez réessayer...")
                }
            )
        }
        .navigationViewStyle(.stack)
    }
}


#Preview {
    LoginView()
}
