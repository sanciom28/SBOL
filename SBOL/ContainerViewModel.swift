//
//  ContainerViewModel.swift
//  SBOL
//
//  Created by Matteo Sancio on 3/25/25.
//


import SwiftUI
import RealityKit

final class ContainerViewModel: ObservableObject {
    @Published var rawJSON: Dictionary<String, Any> = [:]
    
    func addRawJSON(json: Dictionary<String, Any>) {
        self.rawJSON = json
    }    
}
