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
    @State private var boxData: [Int: BoxInfo] = [:] // Dictionary with boxID as key
    @State private var shipmentID: String = ""
    @State private var containersAPI: [Container] = []
    @State private var errorMessage: String?
    
    struct BoxInfo {
        var count: Int
        var color: UIColor
        var dimensions: SIMD3<Float> // (length, height, width)
    }

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
                Text("Enter Shipment ID:")
                    .font(.headline)
                TextField("Shipment ID", text: $shipmentID)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .frame(width: 1000)
                                .padding()
                Button("Load from API") {
                    fetchJSONFromAPI()
                }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
                    .disabled(shipmentID.isEmpty)
                Button("Load from file") {
                    showDocumentPicker = true
                }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
                if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            }
            } else {
                        // UI after JSON is loaded
                        HStack {
                            // Left Panel with Container Details
                            VStack(alignment: .leading) {
                                Text("Container Details")
                                    .font(.title)
                                    .bold()
                                    .padding(.bottom, 10)

                                Text("Shipment ID: \(shipmentID)")
                                    .font(.headline)

                                Text("Total Containers: \(containerCount)")
                                Text("Current Container: \(currentContainerIndex + 1) / \(containerCount)")
                                Text("Boxes in Container: \(boxCount)")
                                
                                Spacer()
                                
                                Button("Reset") {
                                    resetView()
                                }
                                .padding()
                            }
                            .frame(width: 300)
                            .background(Color.gray.opacity(0.2)) // Light gray background
                            .cornerRadius(10)
                            .padding()

                            // 3D Container Display
                            ZStack {
                                RealityView { content in
                                    loadAndRenderFromJSON(content: content)  // Render container
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }

        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(jsonData: $jsonData)
        }

    }
    
    func fetchJSONFromAPI() {
            guard let shipmentNumber = Int(shipmentID) else {
                errorMessage = "Invalid shipment ID"
                return
            }

            let baseURL = "https://lin004.koona.cloud/QPMCalcServer/cfc/QPMShipmentService.cfc?method=exportSBoL&shipment="
            let requestBody: [String: Any] = [
                "qpm_calcdb": "qpm_calcdb",
                "shipment": shipmentNumber
            ]

            guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody),
                  let jsonString = String(data: jsonData, encoding: .utf8)?
                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
                DispatchQueue.main.async { errorMessage = "Failed to encode request JSON" }
                return
            }

            let urlString = baseURL + jsonString
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async { errorMessage = "Invalid API URL" }
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Basic " + Data("matteo.sancio@correo.unimet.edu.ve:tropical019".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        errorMessage = "Request failed: \(error.localizedDescription)"
                        return
                    }

                    guard let data = data else {
                        errorMessage = "No data received"
                        return
                    }

                    self.jsonData = data
                    loadAndRenderFromJSON(content: nil)
                }
            }.resume()
        }

    func loadAndRenderFromJSON(content: RealityKit.RealityViewContent?) {
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

                content?.add(containerEntity)
                containerEntity.position = containerPosition

                if let locations = container["locations"] as? String {
                    let boxDetails = locations.components(separatedBy: "\r").filter { !$0.isEmpty }
                    
                    for boxDetail in boxDetails {
                        boxCount += 1
                        let values = boxDetail.components(separatedBy: ",")

                        if values.count >= 11 {
                            let boxLength = (Float(values[3]) ?? 0.0) / 10000
                            let boxWidth = (Float(values[4]) ?? 0.0) / 10000
                            let boxHeight = (Float(values[5]) ?? 0.0) / 10000
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
            }
        } catch {
            errorMessage = "Error loading JSON: \(error.localizedDescription)"
        }
    }

    // Reset view to ask for JSON again
    func resetView() {
        shipmentID = ""
        jsonData = nil
        errorMessage = nil
        containers.removeAll()
        currentContainerIndex = 0
        boxCount = 0
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
