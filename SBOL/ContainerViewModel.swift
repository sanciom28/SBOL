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
    @Published var containerLength: Float = 0.0
    @Published var containerWidth: Float = 0.0
    @Published var containerHeight: Float = 0.0
    @Published var boxes: String = ""
    
    @Published var containerEntity: ModelEntity? = nil // idk
    
    func updateContainerData(length: Float, width: Float, height: Float, boxes: String) {
        self.containerLength = length
        self.containerWidth = width
        self.containerHeight = height
        self.boxes = boxes
    }
    
    func addRawJSON(json: Dictionary<String, Any>) {
        self.rawJSON = json
    }
    
    func printContainerData() {
        print(containerLength, containerWidth, containerHeight, boxes)
    }
    
}
