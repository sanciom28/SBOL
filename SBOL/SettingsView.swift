//
//  SettingsView.swift
//  SBOL
//
//  Created by Matteo Sancio on 4/28/25.
//


import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Configuración")
                .font(.largeTitle)
                .bold()
                .padding()
            
            Spacer()

            Text("Configurar cantidad de contenedores guardados en búfer")
                .font(.body)
                .padding()

            Text("Borrar historial de contenedores")
                .font(.body)
                .padding()
            
            Spacer()
           
        }
        .navigationTitle("Settings")
    }
}

