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
    
    @State private var containerPosition: SIMD3<Float> = [0, 0.016, 0]
    @State private var containerRotation: Float = 0.5
    @State private var showDocumentPicker = false
    @State private var jsonData: Data? = nil
    @State private var containers: [[String: Any]] = []
    @State private var containerCount: Int = 0
    @State private var currentContainerIndex: Int = 0
    @State private var boxCount: Int = 0

    var body: some View {
        VStack {
            if jsonData == nil {
                Text("SBOL")
                    .font(.system(size: 150))
                    .fontDesign(.monospaced)
                    .bold()
                Text("Spatial Bill of Lading")
                    .font(.system(size: 28))
                    .italic()
                    .padding(.bottom, 80)
                Button("Load from API") {
                    fetchJSONFromAPI()
                }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
                Button("Load from file") {
                    showDocumentPicker = true
                }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
            } else {
                VStack {
                    // Display the current container number and box count
                    Text("Container: \(currentContainerIndex + 1) / \(containerCount)")
                        .font(.headline)
                        .padding(.top)
                    Text("Boxes in this container: \(boxCount)")
                        .font(.subheadline)
                        //.padding(.bottom)

                    // Arrow buttons for navigation
                    HStack {
                        Button(action: showPreviousContainer) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 30))
                        }
                        .disabled(currentContainerIndex == 0) // Disable if at the first container

                        Spacer()

                        Button(action: showNextContainer) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 30))
                        }
                        .disabled(currentContainerIndex == containers.count - 1) // Disable if at the last container
                    }
                    .padding(.horizontal)

                    // Re-add RealityView for rendering the container
                    ZStack {
                        RealityView { content in
                            loadAndRenderFromJSON(content: content)  // Render the current container
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                // Reset button in main window
                Button(action: resetView) {
                    Text("Reset")
                        //.frame(height: 15)
                        //.foregroundColor(.red)
                        .padding()
                        //.background(Color.black.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(jsonData: $jsonData)
        }

    }
    
    func fetchJSONFromAPI() {
        //
    }

    func loadAndRenderFromJSON(content: RealityKit.RealityViewContent) {
        guard let jsonData = jsonData else { return }

        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let containers = jsonObject["containers"] as? [[String: Any]],
               let container = containers.first {
                
                containerCount = containers.count
                
                let containerLength = ((container["container_length"] as? Float ?? 0.0) / 10000) + 0.01
                let containerWidth = ((container["container_width"] as? Float ?? 0.0) / 10000) + 0.01
                let containerHeight = ((container["container_height"] as? Float ?? 0.0) / 10000) + 0.01
                
                let containerMesh = MeshResource.generateBox(size: [containerLength, containerHeight, containerWidth])
                let containerMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.25), isMetallic: false)
                let containerEntity = ModelEntity(mesh: containerMesh, materials: [containerMaterial])
                
                content.add(containerEntity)
                //content.addAnchor(AnchorEntity(world: [0, 0, 0]))  // Create an anchor to add the entity
                //content.anchors[0].addChild(containerEntity)
                containerEntity.position = containerPosition
                
                // Rotate container 45 degrees
                //containerEntity.transform.rotation = simd_quatf(angle: containerRotation, axis: [0, 1, 0])
                
                // Extract the "locations" string and split by \r (which separates each box)
                if let locations = container["locations"] as? String {
                    let boxDetails = locations.components(separatedBy: "\r").filter { !$0.isEmpty }
                    
                    for boxDetail in boxDetails {
                        boxCount += 1
                        let values = boxDetail.components(separatedBy: ",")
                        
                        // Extract the relevant values from the locations string
                        if values.count >= 11 {
                            let boxLength = (Float(values[3]) ?? 0.0) / 10000  // in meters
                            let boxWidth = (Float(values[4]) ?? 0.0) / 10000   // in meters
                            let boxHeight = (Float(values[5]) ?? 0.0) / 10000  // in meters
                            let boxColor = hexStringToColor(hex: values[6])
                            let boxX = (Float(values[8]) ?? 0.0) / 10000       // in meters
                            let boxY = (Float(values[10]) ?? 0.0) / 10000       // in meters
                            let boxZ = (Float(values[9]) ?? 0.0) / 10000      // in meters
                                                        
                            // Create the box entity
                            let boxMesh = MeshResource.generateBox(size: [boxLength, boxHeight, boxWidth])
                            let boxMaterial = SimpleMaterial(color: boxColor, isMetallic: false)
                            let boxEntity = ModelEntity(mesh: boxMesh, materials: [boxMaterial])
                                                        
                            // Adjust the boxes' starting position from the center to the corner
                            let adjustedBoxPosition = SIMD3<Float>(
                                    boxX - (containerLength / 2) + (boxLength / 2),
                                    boxY - (containerHeight / 2) + (boxHeight / 2),
                                    boxZ - (containerWidth / 2) + (boxWidth / 2)
                                )

                            // Position the box inside the container
                            // boxEntity.position = SIMD3<Float>(Float(boxX), Float(boxY), Float(boxZ))
                            boxEntity.position = adjustedBoxPosition
                            
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
    // Load the JSON data and prepare containers
    func loadJSONData() {
        guard let jsonData = jsonData else { return }

        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let loadedContainers = jsonObject["containers"] as? [[String: Any]] {
                containers = loadedContainers
                currentContainerIndex = 0 // Start with the first container
                loadAndRenderCurrentContainer(content: nil) // Load first container immediately
            }
        } catch {
            print("Failed to parse JSON: \(error)")
        }
    }

    // Render the currently selected container
    func loadAndRenderCurrentContainer(content: RealityKit.RealityViewContent?) {
        guard currentContainerIndex < containers.count else { return }

        let container = containers[currentContainerIndex]
        let containerLength = Float(container["container_length"] as? Double ?? 0) / 1000
        let containerWidth = Float(container["container_width"] as? Double ?? 0) / 1000
        let containerHeight = Float(container["container_height"] as? Double ?? 0) / 1000

        let containerEntity = ModelEntity(mesh: MeshResource.generateBox(size: [containerLength, containerHeight, containerWidth]))
        containerEntity.position = containerPosition
        containerEntity.transform.rotation = simd_quatf(angle: containerRotation, axis: [0, 1, 0])

        content?.add(containerEntity)

        if let locationsString = container["locations"] as? String {
            let boxes = createBoxesFromLocations(locationsString)
            boxCount = boxes.count
            for box in boxes {
                containerEntity.addChild(box)
            }
        }
    }

    // Reset view to ask for JSON again
    func resetView() {
        jsonData = nil
        containers.removeAll()
        currentContainerIndex = 0
        boxCount = 0
    }

    // Create boxes from the locations string in JSON
    func createBoxesFromLocations(_ locationsString: String) -> [Entity] {
        var boxes: [Entity] = []
        let boxInfoList = locationsString.split(separator: "\r")

        for boxInfo in boxInfoList {
            let boxEntity = ModelEntity(mesh: MeshResource.generateBox(size: [0.1, 0.1, 0.1]))  // Example size
            boxes.append(boxEntity)
        }

        return boxes
    }

    // Show the previous container
    func showPreviousContainer() {
        if currentContainerIndex > 0 {
            currentContainerIndex -= 1
            loadAndRenderCurrentContainer(content: nil)
        }
    }

    // Show the next container
    func showNextContainer() {
        if currentContainerIndex < containers.count - 1 {
            currentContainerIndex += 1
            loadAndRenderCurrentContainer(content: nil)
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
