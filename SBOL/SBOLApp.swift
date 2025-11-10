//
//  SBOLApp.swift
//  SBOL
//
//  Created by Matteo Sancio on 8/31/24.
//

import SwiftUI

@main
struct SBOLApp: App {
        
    @State private var model = ViewModel()
    @StateObject private var containerVM = ContainerViewModel()
    @StateObject var sharedViewModel = RecentJSONsViewModel()
    @AppStorage("scaleModifier") var scaleModifier: Int = 10
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(model)
                .environmentObject(containerVM)
                .environmentObject(sharedViewModel)
        }
        
        WindowGroup (id: "ContainerView") {
            ContainerView()
                .environment(model)
                .environmentObject(containerVM)
        }
        .windowStyle(.volumetric)
        .defaultSize(CGSize(width: 125*scaleModifier, height: 125*scaleModifier))

        WindowGroup (id: "SettingsView") {
            SettingsView()
                .environment(model)
                .environmentObject(sharedViewModel)
        }.defaultSize(CGSize(width: 600, height: 600))
    }
}
