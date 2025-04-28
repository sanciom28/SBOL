//
//  ContainerView.swift
//  SBOL
//
//  Created by Matteo Sancio on 3/19/25.
//

import SwiftUI
import RealityKit

struct ContainerView: View {
    
    @EnvironmentObject var ContainerViewModel: ContainerViewModel  // Access shared container data
    @State private var containerPosition: SIMD3<Float> = [0, -0.3, 0]
    @State private var angle: Angle = .degrees(0)
    
    var body: some View {
        if ContainerViewModel.rawJSON.isEmpty {
            Text("Ningún contenedor seleccionado.")
                .font(.largeTitle)
        } else {
            ZStack(alignment: .bottom) {
                RealityView { content in
                    renderJSON(content: content)  // Render container
                }
                .rotation3DEffect(angle, axis: .y)
                .animation(.linear(duration: 18).repeatForever(), value: angle)
                .onAppear {
                    angle = .degrees(359)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        }
        
    }
    
    func renderJSON (content: RealityKit.RealityViewContent?) {
        
        do {
            if let containers = ContainerViewModel.rawJSON["containers"] as? [[String: Any]],
               let container = containers.first {
                
                let containerLength = ((container["container_length"] as? Float ?? 0.0) / 10000) + 0.01
                let containerWidth = ((container["container_width"] as? Float ?? 0.0) / 10000) + 0.01
                let containerHeight = ((container["container_height"] as? Float ?? 0.0) / 10000) + 0.01
                
                let containerMesh = MeshResource.generateBox(size: [containerLength, containerHeight, containerWidth])
                let containerMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.25), isMetallic: false)
                let containerEntity = ModelEntity(mesh: containerMesh, materials: [containerMaterial])
                
                content?.add(containerEntity)
                containerEntity.position = containerPosition
                
                if let locations = container["locations"] as? String {
                    let boxDetails = locations.components(separatedBy: "\r").filter { !$0.isEmpty }
                    
                    for boxDetail in boxDetails {
                        let values = boxDetail.components(separatedBy: ",")
                        if values.count >= 11 {
                            var boxLength: Float = 0.0
                            var boxWidth: Float = 0.0
                            if values[7] == "1" {
                                boxLength = -0.001 + (Float(values[4]) ?? 0.0) / 10000
                                boxWidth = -0.001 + (Float(values[3]) ?? 0.0) / 10000
                            } else {
                                boxLength = -0.001 + (Float(values[3]) ?? 0.0) / 10000
                                boxWidth = -0.001 + (Float(values[4]) ?? 0.0) / 10000
                            }
                            let boxHeight = -0.001 + (Float(values[5]) ?? 0.0) / 10000
                            let boxColor = hexStringToColor(hex: values[6])
                            let boxX = (Float(values[8]) ?? 0.0) / 10000
                            let fixY = values[10].components(separatedBy: "\n")[0]
                            let boxY = (Float(fixY) ?? 0.0) / 10000
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
    
}

//    @Environment(\.dismissWindow) private var dismissWindow

//    var body: some View {
//           NavigationSplitView {
//               VStack {
//                   Button(action: {
//                       dismissWindow(id: "ContainerView")
//                   }) {
//                       Text("Dismiss container Window")
//                           .font(.headline)
//                           .padding()
//                           .background(Color.blue)
//                           .foregroundColor(.white)
//                           .cornerRadius(10)
//                   }
//                   .buttonStyle(.plain)
//               }
//               .frame(maxWidth: .infinity, alignment: .top)
//               .navigationTitle("Sidebar")
//           } detail: {
//               Text("Detail")
//           }
//
//       }


