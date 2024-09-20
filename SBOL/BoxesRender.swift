//
//  BoxesRender.swift
//  SBOL
//
//  Created by Matteo Sancio on 9/16/24.
//

import Foundation
import RealityKit
import SwiftUI
import UIKit

func hexStringToUIColor(_ hex: String) -> UIColor {
    var cleanedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

    // Remove the # prefix if it exists
    if cleanedHex.hasPrefix("#") {
        cleanedHex.remove(at: cleanedHex.startIndex)
    }

    if cleanedHex.count == 6 {
        var rgbValue: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }

    // Return a default color (gray) if the hex is invalid
    return UIColor.gray
}


func createBoxEntities(from boxes: [Box]) -> [Entity] {
    var entities: [Entity] = []
    
    for box in boxes {
        // Convert dimensions from millimeters to meters
        let lengthInMeters = box.length / 1000.0
        let widthInMeters = box.width / 1000.0
        let heightInMeters = box.height / 1000.0
                
        // Convert position from millimeters to meters
        let xInMeters = box.x / 1000.0
        let yInMeters = box.y / 1000.0
        let zInMeters = box.z / 1000.0
        
        print("Creating box with dimensions: \(lengthInMeters)m x \(widthInMeters)m x \(heightInMeters)m at position (\(xInMeters), \(yInMeters), \(zInMeters))")

        // Create the box mesh based on length, width, and height
        let boxMesh = MeshResource.generateBox(size: [lengthInMeters, heightInMeters, widthInMeters])
        
        // Convert hex color string to UIColor
        let color = hexStringToUIColor(box.color)
        let boxMaterial = SimpleMaterial(color: color, isMetallic: false)
        
        // Create the entity and set its position based on x, y, z coordinates
        let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
        boxEntity.position = SIMD3(xInMeters, yInMeters, zInMeters)
        
        // Apply orientation (rotation) if necessary
        boxEntity.orientation = simd_quatf(angle: box.orientation * (Float.pi / 180), axis: [0, 1, 0])                

        entities.append(boxEntity)
    }

    return entities
}
