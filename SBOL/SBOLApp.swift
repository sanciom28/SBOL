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
        
        WindowGroup (id: "ContentView") {
            ContentView()
                .environment(model)
                .environmentObject(containerVM)
                .environmentObject(sharedViewModel)
        }
        
        WindowGroup (id: "ContainerView") {
            ContainerView()
                .environment(model)
                .environmentObject(containerVM)
                .frame(width: 1250, height: 1250)
        }
        .windowStyle(.volumetric)
        .windowResizability(.contentSize)
    }
}
