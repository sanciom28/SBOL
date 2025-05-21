//
//  SettingsView.swift
//  SBOL
//
//  Created by Matteo Sancio on 4/28/25.
//


import SwiftUI

struct SettingsView: View {
    
    @AppStorage("scaleModifier") var scaleModifier: Int = 10
    @AppStorage("maxStoredContainers") var maxStoredContainers: Int = 20
    @EnvironmentObject var sharedViewModel: RecentJSONsViewModel
    
    var body: some View {
        VStack {
            Text("Configuración")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Spacer()
            
            Text("Escala del contenedor")
            //.font(.headline)
            Slider(value: Binding(
                get: { Double(scaleModifier) },
                set: { scaleModifier = Int($0) }
            ), in: 1...100, step: 1)
            .padding()
            Text("\(scaleModifier)%")
            //.font(.subheadline)
                .padding(.top, -10)
            
            Text("Cantidad de contenedores guardados en historial")
            Slider(value: Binding(
                get: { Double(maxStoredContainers) },
                set: { maxStoredContainers = Int($0) }
            ), in: 1...100, step: 1)
            .padding()
            Text("\(maxStoredContainers) contenedores")
            //.font(.subheadline)
                .padding(.top, -10)

            
            Button("Restaurar valores por defecto") {
                print("Scale value before restoring: \(scaleModifier)")
                print("Max buffer value before restoring: \(maxStoredContainers)")
                scaleModifier = 10
                maxStoredContainers = 20
            }
            
            Button("Borrar historial de contenedores") {
                sharedViewModel.clearRecentJSONs()
                print(sharedViewModel.recentJSONs)
            }
            
            Spacer()
           
        }
        .navigationTitle("Settings")
    }
}

