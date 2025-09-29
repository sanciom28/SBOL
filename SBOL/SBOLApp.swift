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
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(model)
                .environmentObject(containerVM)
                .environmentObject(sharedViewModel)
        }//.defaultSize(CGSize(width: 1100, height: 750))
        
        
        WindowGroup (id: "ContainerView") {
            ContainerView()
                .environment(model)
                .environmentObject(containerVM)
                
        }
        .windowStyle(.volumetric)

        WindowGroup (id: "SettingsView") {
            SettingsView()
                .environment(model)
                .environmentObject(sharedViewModel)
        }.defaultSize(CGSize(width: 600, height: 600))
    }
}
