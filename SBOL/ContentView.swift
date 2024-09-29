//
//  ContentView.swift
//  SBOL
//
//  Created by Matteo Sancio on 8/31/24.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    
    // State variables to store the container's position and rotation
    @State private var containerPosition: SIMD3<Float> = [0, 0, 0]  // Initially on the floor, 2 meters away from the camera
    @State private var containerRotation: Float = 0.0  // Initially no rotation around the Y-axis
        
    var body: some View {
        RealityView { content in
            // Load and parse the JSON data from the bundle
            guard let jsonFileURL = Bundle.main.url(forResource: "SingleBox", withExtension: "json") else {
                print("Failed to find JSON file in bundle")
                return
            }
            
            do {
                let jsonData = try Data(contentsOf: jsonFileURL)
                print(jsonData)
                if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                   let containers = jsonObject["containers"] as? [[String: Any]],
                   let container = containers.first {
                    
                    // Extract container dimensions (in mm, convert to meters)
                    let containerLength = (container["container_length"] as? Float ?? 0.0) / 10000
                    let containerWidth = (container["container_width"] as? Float ?? 0.0) / 10000
                    let containerHeight = (container["container_height"] as? Float ?? 0.0) / 10000
                    
                    // Create a semitransparent volume (container)
                    let containerMesh = MeshResource.generateBox(size: [containerLength, containerHeight, containerWidth])
                    let containerMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.8), isMetallic: false)
                    let containerEntity = ModelEntity(mesh: containerMesh, materials: [containerMaterial])
                    
                    print("Creating container with dimensions: \(containerLength)m x \(containerHeight)m x \(containerWidth)m")
                    
                    // Center the container in the scene
                    //containerEntity.position = [0, containerHeight / 2, 0]
                    
                    // testing container positions
                    //containerEntity.position = [0,containerHeight/2,-0.4]
                    
                    // Rotate the container 45 degrees around the Y-axis
                    //let angle = Float(45 * 3.14159 / 180)  // Convert degrees to radians
                    //containerEntity.orientation = simd_quatf(angle: angle, axis: [0, 1, 0])  // Rotation around Y-axis

                    // Set the container's position and rotation
                    containerEntity.position = containerPosition
                    containerEntity.orientation = simd_quatf(angle: containerRotation, axis: [0, 1, 0])  // Rotate around Y-axis
                                
                    
                    content.add(containerEntity)
                    
                    
                    
                    
                    
                    // Extract the "locations" string and split by \r (which separates each box)
                    if let locations = container["locations"] as? String {
                        let boxDetails = locations.components(separatedBy: "\r").filter { !$0.isEmpty }
                        
                        for boxDetail in boxDetails {
                            let values = boxDetail.components(separatedBy: ",")
                            
                            // Extract the relevant values from the locations string
                            if values.count >= 11 {
                                let boxLength = (Float(values[3]) ?? 0.0) / 10000  // in meters
                                let boxWidth = (Float(values[4]) ?? 0.0) / 10000   // in meters
                                let boxHeight = (Float(values[5]) ?? 0.0) / 10000  // in meters
                                let boxColor = hexStringToColor(hex: values[6])
                                let boxX = (Float(values[8]) ?? 0.0) / 10000       // in meters
                                let boxY = (Float(values[9]) ?? 0.0) / 10000       // in meters
                                let boxZ = (Float(values[10]) ?? 0.0) / 10000      // in meters
                                
                                // Create the box entity
                                let boxMesh = MeshResource.generateBox(size: [boxLength, boxHeight, boxWidth])
                                let boxMaterial = SimpleMaterial(color: boxColor, isMetallic: true)
                                let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
                                
                                print("Creating box 📦 with dimensions: \(containerLength)m x \(containerHeight)m x \(containerWidth)m")
                                
                                // Position the box inside the container
                                boxEntity.position = SIMD3<Float>(Float(boxX), Float(boxY), Float(boxZ))
                                
                                // Add the box to the container
                                containerEntity.addChild(boxEntity)
                            }
                        }
                    }
                    
                } else {
                    print("Failed to parse the JSON data")
                }
            } catch {
                print("Error loading the JSON file: \(error)")
            }
        }
        // Add gestures for moving and rotating the container
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Update the position based on the drag (X and Z axes)
                    let deltaX = Float(value.translation.width) * 0.01  // Scale down the translation to meters
                    let deltaZ = Float(value.translation.height) * 0.01
                    containerPosition.x += deltaX
                    containerPosition.z += deltaZ
                }
        )
        .gesture(
            RotationGesture()
                .onChanged { value in
                    // Update the rotation around the Y-axis based on the user's rotation gesture
                    containerRotation = Float(value.radians)
                }
        )
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

}
