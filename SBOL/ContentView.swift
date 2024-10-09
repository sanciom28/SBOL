//
//  ContentView.swift
//  SBOL
//
//  Created by Matteo Sancio on 8/31/24.
//

import SwiftUI
import RealityKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var containerPosition: SIMD3<Float> = [0, 0, 0]
    @State private var containerRotation: Float = 0.0
    @State private var showDocumentPicker = false
    @State private var jsonData: Data? = nil

    
    var body: some View {
        VStack {
            if jsonData == nil {
                Button("Load JSON") {
                    showDocumentPicker = true
                }
            } else {
                ZStack {
                    RealityView { content in
                        loadAndRenderFromJSON(content: content)
                    }
                    // Gesture handlers...
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: resetView) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(jsonData: $jsonData)
        }
        // Gesture handlers for moving and rotating...

    }

    
    func loadAndRenderFromJSON(content: RealityKit.RealityViewContent) {
        guard let jsonData = jsonData else { return }

        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let containers = jsonObject["containers"] as? [[String: Any]],
               let container = containers.first {
                
                let containerLength = ((container["container_length"] as? Float ?? 0.0) / 10000) + 0.01
                let containerWidth = ((container["container_width"] as? Float ?? 0.0) / 10000) + 0.01
                let containerHeight = ((container["container_height"] as? Float ?? 0.0) / 10000) + 0.01
                
                let containerMesh = MeshResource.generateBox(size: [containerLength, containerHeight, containerWidth])
                let containerMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.7), isMetallic: false)
                let containerEntity = ModelEntity(mesh: containerMesh, materials: [containerMaterial])
                
                content.add(containerEntity)
                //content.addAnchor(AnchorEntity(world: [0, 0, 0]))  // Create an anchor to add the entity
                //content.anchors[0].addChild(containerEntity)
                
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
                            let boxMaterial = SimpleMaterial(color: boxColor, isMetallic: false)
                            let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
                            
                            print("Creating box 📦 with dimensions: \(boxLength)m x \(boxHeight)m x \(boxWidth)m")
                            
                            // Adjust the boxes' starting position from the center to the corner
                            let adjustedBoxPosition = SIMD3<Float>(
                                    boxX - (containerLength / 2) + (boxLength / 2),
                                    boxY - (containerHeight / 2) + (boxHeight / 2),
                                    boxZ - (containerWidth / 2) + (boxWidth / 2)
                                )

                            // Position the box inside the container
                            // boxEntity.position = SIMD3<Float>(Float(boxX), Float(boxY), Float(boxZ))
                            boxEntity.position = adjustedBoxPosition
                            print(adjustedBoxPosition)
                            
                            // Add the box to the container
                            containerEntity.addChild(boxEntity)
                            
                            // figuring out the delta between the container and the boxes
                            print("The boxes extend beyond the container in these values:\n\(boxX+boxLength-containerLength)\n\(boxY+boxHeight-containerHeight)\n\(boxZ+boxWidth-containerWidth)")
                        }
                    }
                }
            }
        } catch {
            print("Error loading the JSON file: \(error)")
        }
    }
    
    // This function will clear the rendered content and reset the app to its initial state.
    func resetView() {
        // Reset JSON data to nil, which will remove rendered content
        jsonData = nil
        containerPosition = [0, 0, 0]
        containerRotation = 0.0
        // You can also reset any other states or variables if needed
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

struct DocumentPickerView: UIViewControllerRepresentable {
    @Binding var jsonData: Data?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView

        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                do {
                    parent.jsonData = try Data(contentsOf: url)
                } catch {
                    print("Failed to load JSON data: \(error)")
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("Document picker was cancelled")
        }
        
        
    }
    
}
