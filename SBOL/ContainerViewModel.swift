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
        filterJSON(boxID: "1")
    }
    
    func filterJSON(boxID: String) {
        
//        if let boxes = rawJSON["locations"] as? String {
//            if let box = boxes.first(where: { ($0["id"] as? String) == boxID }) {
//                print("Box found: \(box)")
//                // Process the box data as needed
//            } else {
//                print("Box with ID \(boxID) not found.")
//            }
//        } else {
//            print("No boxes found in JSON.")
//        }
    }
    
}
