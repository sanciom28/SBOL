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
    @Published var boxes: String = ""
    
    func updateContainerData(length: Float, width: Float, height: Float, boxes: String) {
        self.containerLength = length
        self.containerWidth = width
        self.containerHeight = height
        self.boxes = boxes
    }
    
    func createContainer() {
        
        let containerLength = ((containerLength) / 10000) + 0.01
        let containerWidth = ((containerWidth) / 10000) + 0.01
        let containerHeight = ((containerHeight) / 10000) + 0.01
        
        let containerMesh = MeshResource.generateBox(size: [containerLength, containerHeight, containerWidth])
        let containerMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.25), isMetallic: false)
        let containerEntity = ModelEntity(mesh: containerMesh, materials: [containerMaterial])
        
        //content?.add(containerEntity)
        //containerEntity.position = containerPosition
        
        if boxes != "" {
            let boxDetails = boxes.components(separatedBy: "\r").filter { !$0.isEmpty }
            
            for boxDetail in boxDetails {
                let values = boxDetail.components(separatedBy: ",")
                if values.count >= 11 {
                    let boxLength = -0.001 + (Float(values[3]) ?? 0.0) / 10000
                    let boxWidth = -0.001 + (Float(values[4]) ?? 0.0) / 10000
                    let boxHeight = -0.001 + (Float(values[5]) ?? 0.0) / 10000
                    let boxColor = hexStringToColor(hex: values[6])
                    let boxX = (Float(values[8]) ?? 0.0) / 10000
                    let boxY = (Float(values[10]) ?? 0.0) / 10000
                    let boxZ = (Float(values[9]) ?? 0.0) / 10000
                    
                    let boxMesh = MeshResource.generateBox(size: [boxLength, boxHeight, boxWidth])
                    let boxMaterial = SimpleMaterial(color: boxColor, isMetallic: false)
                    let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
                    
                    let adjustedBoxPosition = SIMD3<Float>(
                        boxX - (containerLength / 2) + (boxLength / 2),
                        boxY - (containerHeight / 2) + (boxHeight / 2),
                        boxZ - (containerWidth / 2) + (boxWidth / 2)
                    )
                    
                    boxEntity.position = adjustedBoxPosition
                    containerEntity.addChild(boxEntity)
                    
                }
                
            }
        }
        
        
        // Helper function to convert hex color code to UIColor
        func hexStringToColor(hex: String) -> UIColor {
            var cleanedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            
            if cleanedHex.hasPrefix("#") {
                cleanedHex.remove(at: cleanedHex.startIndex)
            }
            
            if cleanedHex.count != 6 {
                return UIColor.gray // Default to gray if invalid
            }
            
            var rgbValue: UInt64 = 0
            Scanner(string: cleanedHex).scanHexInt64(&rgbValue)
            
            let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
            
            return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        }
        
        func printContainerData() {
            print(containerLength, containerWidth, containerHeight, boxes)
        }
        
    }
}
