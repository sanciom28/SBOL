//
//  ContainerView.swift
//  SBOL
//
//  Created by Matteo Sancio on 3/19/25.
//

import SwiftUI
import RealityKit

struct ContainerView: View {
    
    @EnvironmentObject var containerViewModel: ContainerViewModel  // Access shared container data
    @State private var containerPosition: SIMD3<Float> = [0, -0.3, 0]
    @State private var angle: Angle = .degrees(0)
    
    @AppStorage("scaleModifier") var scaleModifier: Int = 10000
    @AppStorage("rotationSpeed") var rotationSpeed: Double = 3.0
    
    @State private var isLoading: Bool = true
    
    var body: some View {
        if containerViewModel.rawJSON.isEmpty {
            Text("Ningún contenedor seleccionado.")
                .font(.largeTitle)
        } else {
            ZStack(alignment: .bottom) {
                RealityView { content in
                    DispatchQueue.main.async {
                        isLoading = true
                    }
                    renderJSON(content: content)  // Render container
                    DispatchQueue.main.async {
                        isLoading = false
                    }
                }
                .rotation3DEffect(angle, axis: .y)
                .animation(.linear(duration: (60/rotationSpeed)*100).repeatForever(), value: angle)
                .onAppear {
                    angle = .degrees(35999)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                if isLoading {
                    ProgressView()
                        .padding(.bottom, 80)
                }
            }
        }
    }
    
    func renderJSON (content: RealityKit.RealityViewContent?) {
        
        let scale = (1/Float(scaleModifier)) * 100000
        let boxPadding = 10/scale
        
        let container = containerViewModel.rawJSON
        
        let containerLength = ((container["container_length"] as? Float ?? 0.0) / scale) + boxPadding*2
        let containerWidth = ((container["container_width"] as? Float ?? 0.0) / scale) + boxPadding*2
        let containerHeight = ((container["container_height"] as? Float ?? 0.0) / scale) + boxPadding*2
        
        let containerMesh = MeshResource.generateBox(size: [containerLength, containerHeight, containerWidth])
        let containerMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.25), isMetallic: false)
        let containerEntity = ModelEntity(mesh: containerMesh, materials: [containerMaterial])
        
        containerEntity.position = containerPosition
        content?.add(containerEntity)
        
        if let locations = container["locations"] as? String {
            let boxDetails = locations.components(separatedBy: "\r").filter { !$0.isEmpty }
            
            for boxDetail in boxDetails {
                let values = boxDetail.components(separatedBy: ",")
                if values.count >= 11 {
                    var boxLength: Float = 0.0
                    var boxWidth: Float = 0.0
                    if values[7] == "1" {
                        boxLength = -boxPadding + (Float(values[4]) ?? 0.0) / scale
                        boxWidth = -boxPadding + (Float(values[3]) ?? 0.0) / scale
                    } else {
                        boxLength = -boxPadding + (Float(values[3]) ?? 0.0) / scale
                        boxWidth = -boxPadding + (Float(values[4]) ?? 0.0) / scale
                    }
                    let boxHeight = -boxPadding + (Float(values[5]) ?? 0.0) / scale
                    let boxColor = hexStringToColor(hex: values[6])
                    let boxX = (Float(values[8]) ?? 0.0) / scale
                    let fixY = values[10].components(separatedBy: "\n")[0]
                    let boxY = (Float(fixY) ?? 0.0) / scale
                    let boxZ = (Float(values[9]) ?? 0.0) / scale
                    
                    let boxMesh = MeshResource.generateBox(size: [boxLength, boxHeight, boxWidth])
                    let boxMaterial = SimpleMaterial(color: boxColor, isMetallic: false)
                    let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
                    
                    let adjustedBoxPosition = SIMD3<Float>(
                        boxX - (containerLength / 2) + (boxLength / 2) + boxPadding,
                        boxY - (containerHeight / 2) + (boxHeight / 2) + boxPadding,
                        boxZ - (containerWidth / 2) + (boxWidth / 2) + boxPadding
                    )
                    
                    boxEntity.position = adjustedBoxPosition
                    containerEntity.addChild(boxEntity)
                    
                }
            }
        }
        
    }
    
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
