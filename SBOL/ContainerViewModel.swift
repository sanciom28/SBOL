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
    //@Published var containerEntity: ModelEntity? = nil // idk
    
    func addRawJSON(json: Dictionary<String, Any>) {
        self.rawJSON = json
    }
    
    func filterBoxes() {
        //
    }
    
}
