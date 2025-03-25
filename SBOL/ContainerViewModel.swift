//
//  ContainerViewModel.swift
//  SBOL
//
//  Created by Matteo Sancio on 3/25/25.
//


import SwiftUI
import RealityKit

class ContainerViewModel: ObservableObject {
    @Published var containerLength: Float = 0.0
    @Published var containerWidth: Float = 0.0
    @Published var containerHeight: Float = 0.0
    @Published var boxes: [ModelEntity] = []
    
    func updateContainerData(length: Float, width: Float, height: Float, boxes: [ModelEntity]) {
        self.containerLength = length
        self.containerWidth = width
        self.containerHeight = height
        self.boxes = boxes
    }
}
