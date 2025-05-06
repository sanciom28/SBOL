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
    
    @State private var containerPosition: SIMD3<Float> = [0, -50, 0]
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
    
    @EnvironmentObject var containerViewModel: ContainerViewModel
        
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Environment(ViewModel.self) var model
    
    @State private var recentJSONs: [Data] = [] // Buffer for recent JSONs
    
    // Struct for table purposes
    struct BoxInfo {
        var count: Int
        var color: UIColor
        var dimensions: SIMD3<Float> // (length, height, width)
    }
    
    var body: some View {
        
        @Bindable var model = model
        
        
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
                Text("Introduzca ID del contenedor:")
                    .font(.headline)
                TextField("ID del contenedor", text: $shipmentID)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .frame(width: 500)
                    .padding()
                    .onSubmit {
                        fetchJSONFromAPI()
                    }
                Button("Cargar desde API") {
                    loadRecentJSONs()
                    fetchJSONFromAPI()
                }
                .frame(width: 360, height: 80)
                .font(.system(size: 24))
                .disabled(shipmentID.isEmpty)
                .padding(.bottom, -10)
                Button("Cargar desde archivo") {
                    showDocumentPicker = true
                }
                .frame(width: 360, height: 80)
                .font(.system(size: 24))
                .padding(.bottom, -10)
                //                Button(action: {
                //                    openWindow(id: "ContainerView")
                //                    print("my container window.")
                //                }) {
                //                    Text("Ventana mía de prueba")
                //                }
                //                .frame(width: 360, height: 80)
                //                .font(.system(size: 24))
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                Button("Cargar último contenedor") {
                    loadRecentJSONs()
                    print("Recent JSONs: \(recentJSONs.count)")
                    jsonData = recentJSONs.last
                    loadAndRenderFromJSON(content: nil)
                }
                .frame(width: 360, height: 80)
                .font(.system(size: 24))
                Button(action: {
                    openWindow(id: "SettingsView")
                }) {
                    Image(systemName: "gearshape.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                    
                }
                .frame(width: 30, height: 30)
                
                
                //                Toggle("Open the test volume", isOn: $model.secondaryVolumeIsShowing)
                //                    .toggleStyle(.button)
                //                    .onChange(of: model.secondaryVolumeIsShowing) { _, isShowing in
                //                        if isShowing {
                //                            openWindow(id: "secondaryVolume")
                //                        } else {
                //                            dismissWindow(id: "secondaryVolume")
                //                        }
                //                    }
            } else {
                // UI after JSON is loaded
                // Left Panel with Container Details
                VStack {
                    Spacer()
                    Text("Detalles del contenedor")
                        .font(.title)
                        .bold()
                        .padding(.bottom, 10)
                    
                    Text("ID del Envío: \(shipmentID)")
                        .font(.headline)
                    
                    Text("Num. total de contenedores: \(containerCount)")
                    Text("Contenedor actual: \(currentContainerIndex + 1) / \(containerCount)")
                    Text("Num. total de cajas: \(boxCount)")
                    Toggle("Mostrar contenedor", isOn: $model.secondaryVolumeIsShowing)
                        .toggleStyle(.button)
                        .onChange(of: model.secondaryVolumeIsShowing) { _, isShowing in
                            if isShowing {
                                openWindow(id: "ContainerView")
                            } else {
                                dismissWindow(id: "ContainerView")
                            }
                        }
                    
                    Spacer()
                    Text("Agregar tabla aquí")
                    Spacer()
                    
                    Button("Volver") {
                        resetView()
                    }
                    .padding()
                }
                
                //.frame(width: 300)
                //.background(Color.gray.opacity(0.2)) // Light gray background
                //.cornerRadius(10)
                //.padding()

                RealityView { content in
                    loadAndRenderFromJSON(content: nil) // Render container
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                
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
        request.setValue("Basic " + Data("matteo.sancio@correo.unimet.edu.ve:tropical019".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization") //TODO: this is unsecure. encrypt
        
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
                
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if jsonObject!["errormessage"] != nil {
                        errorMessage = "Shipment not found"
                        return
                    }
                } catch {
                    errorMessage = "Error parsing JSON: \(error.localizedDescription)"
                    return
                }
                
                self.jsonData = data
                addToRecentJSONs(data)
                
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
                
                if (container["locations"] != nil) {
                    
                    containerViewModel.addRawJSON(json: jsonObject)
                }
                
            }
        } catch {
            errorMessage = "Error loading JSON: \(error.localizedDescription)"
        }
    }
    
    func addToRecentJSONs(_ json: Data) {
        if recentJSONs.count >= 20 {
            recentJSONs.removeFirst() // Remove the oldest JSON if buffer exceeds 20
        }
        if recentJSONs.contains(json) {
            return // Avoid adding duplicates
        }
        recentJSONs.append(json)
        saveRecentJSONs()
    }
    
    // Save the buffer to UserDefaults
    func saveRecentJSONs() {
        let jsonStrings = recentJSONs.map { String(data: $0, encoding: .utf8) ?? "" }
        UserDefaults.standard.set(jsonStrings, forKey: "RecentJSONs")
    }
    
    // Load the buffer from UserDefaults
    func loadRecentJSONs() {
        if let jsonStrings = UserDefaults.standard.array(forKey: "RecentJSONs") as? [String] {
            recentJSONs = jsonStrings.compactMap { $0.data(using: .utf8) }
        }
    }
    
    // Delete the buffer
    func deleteRecentJSONs() {
        recentJSONs.removeAll()
        UserDefaults.standard.removeObject(forKey: "RecentJSONs")
    }
    
    // Reset view to ask for JSON again
    func resetView() {
        shipmentID = ""
        jsonData = nil
        errorMessage = nil
        containers.removeAll()
        currentContainerIndex = 0
        boxCount = 0
        dismissWindow(id: "ContainerView")
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

