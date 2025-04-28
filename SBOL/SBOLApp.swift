//
//  SBOLApp.swift
//  SBOL
//
//  Created by Matteo Sancio on 8/31/24.
//

import SwiftUI

@main
struct SBOLApp: App {
    
    @State private var appModel = AppModel()
    
    @State private var model = ViewModel()
    
    @StateObject private var containerVM = ContainerViewModel()
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environment(model)
                .environmentObject(containerVM)
        }.defaultSize(CGSize(width: 1100, height: 750))
        
        
        WindowGroup (id: "ContainerView") {
            ContainerView()
                .environment(model)
                .environmentObject(containerVM)
            
        }
        .windowStyle(.volumetric)
        
        WindowGroup (id: "dddd") {
            SecondaryVolumeView()
                .environment(model)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.1, height: 0.1, depth: 0.1, in: .meters)
        
        WindowGroup (id: "SettingsView") {
            SettingsView()
                .environment(model)
        }.defaultSize(CGSize(width: 500, height: 500))
    }
}
