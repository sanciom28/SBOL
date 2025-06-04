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
    @State private var errorMessage: String?
    @State private var ajustes: Bool = false
    @State private var volumeEfficiency: Double = 0.0
    @State private var historyIndex: Int = 0
    
    @EnvironmentObject var containerViewModel: ContainerViewModel
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Environment(ViewModel.self) var model
    
    @EnvironmentObject var sharedViewModel: RecentJSONsViewModel
    
    @AppStorage("scaleModifier") var scaleModifier: Int = 10
    @AppStorage("rotationSpeed") var rotationSpeed: Double = 3.0
    @AppStorage("maxStoredContainers") var maxStoredContainers: Int = 20
    
    @State private var filteredJsonData: Data? = nil
    
    @State private var dummyBoxInfo = [
        BoxInfo(count: "10", color: "UIColor.red", dimensions: "SIMD3<Float>(1, 1, 1)"),
        BoxInfo(count: "30", color: "UIColor.blue", dimensions: "SIMD3<Float>(3, 3, 3)"),
        BoxInfo(count: "20", color: "UIColor.green", dimensions: "SIMD3<Float>(2, 2, 2)"),
        BoxInfo(count: "10", color: "UIColor.red", dimensions: "SIMD3<Float>(1, 1, 1)"),
        BoxInfo(count: "30", color: "UIColor.blue", dimensions: "SIMD3<Float>(3, 3, 3)"),
        BoxInfo(count: "20", color: "UIColor.green", dimensions: "SIMD3<Float>(2, 2, 2)"),
        BoxInfo(count: "10", color: "UIColor.red", dimensions: "SIMD3<Float>(1, 1, 1)"),
        BoxInfo(count: "30", color: "UIColor.blue", dimensions: "SIMD3<Float>(3, 3, 3)"),
        BoxInfo(count: "20", color: "UIColor.green", dimensions: "SIMD3<Float>(2, 2, 2)"),
        BoxInfo(count: "10", color: "UIColor.red", dimensions: "SIMD3<Float>(1, 1, 1)"),
        BoxInfo(count: "30", color: "UIColor.blue", dimensions: "SIMD3<Float>(3, 3, 3)"),
        BoxInfo(count: "20", color: "UIColor.green", dimensions: "SIMD3<Float>(2, 2, 2)"),
        BoxInfo(count: "10", color: "UIColor.red", dimensions: "SIMD3<Float>(1, 1, 1)"),
        BoxInfo(count: "30", color: "UIColor.blue", dimensions: "SIMD3<Float>(3, 3, 3)"),
        BoxInfo(count: "20", color: "UIColor.green", dimensions: "SIMD3<Float>(2, 2, 2)"),
        BoxInfo(count: "10", color: "UIColor.red", dimensions: "SIMD3<Float>(1, 1, 1)"),
        BoxInfo(count: "30", color: "UIColor.blue", dimensions: "SIMD3<Float>(3, 3, 3)"),
        BoxInfo(count: "20", color: "UIColor.green", dimensions: "SIMD3<Float>(2, 2, 2)")
    ]
    
    var body: some View {
        
        @Bindable var model = model
        
        VStack {
            
            if jsonData == nil {
                if ajustes {
                    Text("Configuración")
                        .font(.system(size: 36))
                        .bold()
                        .padding(.bottom, 50)
                    Text("Escala del contenedor")
                    Slider(value: Binding(
                        get: { Double(scaleModifier) },
                        set: { scaleModifier = Int($0) }
                    ), in: 1...100, step: 1)
                    .frame(width: 500)
                    if scaleModifier == 100 {
                        Text("Tamaño real")
                            .padding(.bottom, 20)
                    } else {
                        Text("\(scaleModifier)% del tamaño real")
                            .padding(.bottom, 20)
                    }
                    Text("Velocidad de rotación de contenedor")
                    Slider(value: Binding(
                        get: { Double(rotationSpeed) },
                        set: { rotationSpeed = Double($0) }
                    ), in: 0...10, step: 1)
                    .frame(width: 500)
                    if rotationSpeed == 0 {
                        Text("Rotación desactivada")
                            .padding(.bottom, 20)
                    } else {
                        Text("\(Int(rotationSpeed)) rotaciones por minuto")
                            .padding(.bottom, 20)
                    }
                    Text("Cantidad de contenedores guardados en historial")
                    Slider(value: Binding(
                        get: { Double(maxStoredContainers) },
                        set: { maxStoredContainers = Int($0) }
                    ), in: 1...100, step: 1)
                    .frame(width: 500)
                    if maxStoredContainers == 1 {
                        Text("1 contenedor")
                            .padding(.bottom, 20)
                    } else {
                        Text("\(maxStoredContainers) contenedores")
                            .padding(.bottom, 20)
                    }
                    Button("Restaurar valores por defecto") {
                        scaleModifier = 10
                        maxStoredContainers = 20
                        rotationSpeed = 3.0
                    }
                    .font(.system(size: 22))
                    .padding(.top, 20)
                    Button("Borrar historial de contenedores") {
                        print(sharedViewModel.recentJSONs)
                        deleteRecentJSONs()
                        print(sharedViewModel.recentJSONs)
                    }
                    .font(.system(size: 22))
                    .padding()
                } else {
                    Text("SBOL")
                        .font(.system(size: 150))
                        .fontDesign(.monospaced)
                        .bold()
                    Text("Spatial Bill of Lading")
                        .font(.system(size: 28))
                        .italic()
                        .padding(.bottom, 60)
                    Text("Introduzca ID del contenedor:")
                        .font(.headline)
                    TextField("ID del contenedor", text: $shipmentID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 500)
                        .padding()
                        .onSubmit {
                            fetchJSONFromAPI()
                        }
                    Button("Cargar desde API") {
                        fetchJSONFromAPI()
                    }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
                    .disabled(shipmentID.isEmpty)
                    .padding(.bottom, -10)
                    Button("Cargar desde archivo") {
                        showDocumentPicker = true
                    }
                    .sheet(isPresented: $showDocumentPicker) {
                        DocumentPickerView(jsonData: $jsonData)
                    }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
                    .padding(.bottom, -10)
                    
                    Button("Cargar último contenedor") {
                        loadRecentJSONs()
                        if sharedViewModel.recentJSONs.isEmpty {
                            errorMessage = "No hay contenedores recientes"
                            return
                        }
                        
                    }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
                    .padding(.bottom, 5)
                }
                
                Button(action: {
                    ajustes.toggle()
                }) {
                    Image(systemName: ajustes ? "xmark.circle.fill" : "gear")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                .frame(width: 30, height: 30)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.bottom)
                }
            } else {
                // UI after JSON is loaded
                ZStack {
                    HStack(alignment: .top) {
                        VStack(spacing: 4) {
                            Text("Detalles del contenedor")
                                .font(.title)
                                .bold()
                                .padding()
                            
                            VStack(alignment: .leading) {
                                if shipmentID != "" {
                                    Text("ID del Envío: \(shipmentID)")
                                }
                                Text("Num. total de contenedores: \(containerCount)")
                                Text("Contenedor actual: \(currentContainerIndex + 1) / \(containerCount)")
                                Text("Num. total de cajas: \(boxCount)")
                                Text("Eficiencia de llenado: \(String(format: "%.2f", volumeEfficiency))%")
                                    .padding(.bottom, 10)
                            }
                            HStack {
                                Button(action: {
                                    currentContainerIndex-=1
                                    model.secondaryVolumeIsShowing = false
                                    loadAndRenderFromJSON(content: nil) // Render container
                                    
                                }) {
                                    Image(systemName: "arrow.left")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }.padding()
                                    .disabled(currentContainerIndex == 0)

                                Button(action: {
                                    currentContainerIndex+=1
                                    model.secondaryVolumeIsShowing = false
                                    loadAndRenderFromJSON(content: nil) // Render container
                                    
                                }) {
                                    Image(systemName: "arrow.right")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }.padding()
                                    .disabled(currentContainerIndex >= containerCount-1)
                            }
                            Toggle("Mostrar contenedor", isOn: $model.secondaryVolumeIsShowing)
                                .toggleStyle(.button)
                                .onChange(of: model.secondaryVolumeIsShowing) { _, isShowing in
                                    if isShowing {
                                        openWindow(id: "ContainerView")
                                    } else {
                                        dismissWindow(id: "ContainerView")
                                    }
                                }.padding()

                            Spacer()
                            Button("Volver") {
                                resetView()
                            }.padding()
                        }.padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(15)

                        Table(dummyBoxInfo) {
                            TableColumn("ID", value: \.count)
                            TableColumn("Cantidad", value: \.count)
                            TableColumn("Color", value: \.color)
                            TableColumn("Dimensiones (LxHxW)", value: \.dimensions)
                        }.padding()
                            .frame(maxHeight: 300)
                    }
                    
                    RealityView { content in
                        loadAndRenderFromJSON(content: nil) // Render container
                    }
                    //                .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    func loadAndRenderFromJSON(content: RealityKit.RealityViewContent?) {
        guard var jsonData = jsonData else { return }
        
        if let filteredData = filteredJsonData {
            jsonData = filteredData
        }
        
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let containers = jsonObject["containers"] as? [[String: Any]] {
                
                let currentContainer = containers[currentContainerIndex]
                
                boxCount = jsonObject["total_boxes"] as? Int ?? 0
                volumeEfficiency = (currentContainer["cont_volef"] as? Double ?? 0.0) * 100
                
                let shipID = jsonObject["shipment"] as? Int ?? 0
                print("ship ID: \(shipID)")
                if shipID != 0 {
                    shipmentID = String(shipID)
                }
                
                containerCount = containers.count
                
                if (currentContainer["locations"] != nil) {
                    containerViewModel.addRawJSON(json: currentContainer)
                }
                
            }
        } catch {
            errorMessage = "Error loading JSON: \(error.localizedDescription)"
        }
    }
    
    func fetchJSONFromAPI() {
        guard let shipmentNumber = Int(shipmentID) else {
            errorMessage = "ID de envío inválido"
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
            DispatchQueue.main.async { errorMessage = "URL del API inválido" }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic " + Data("matteo.sancio@correo.unimet.edu.ve:tropical019".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Fallo en solicitud: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No se recibieron datos"
                    return
                }
                
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if jsonObject!["errormessage"] != nil {
                        errorMessage = "Envío no encontrado"
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
    
    func addToRecentJSONs(_ json: Data) {
        if sharedViewModel.recentJSONs.count >= maxStoredContainers {
            sharedViewModel.recentJSONs.removeFirst()
        }
        if sharedViewModel.recentJSONs.last == json {
            print("Duplicate JSON found, not adding to recent JSONs.")
            return // Avoid adding duplicates back to back
        }
        sharedViewModel.recentJSONs.append(json)
        saveRecentJSONs()
    }
    
    // Save the buffer to UserDefaults
    func saveRecentJSONs() {
        let jsonStrings = sharedViewModel.recentJSONs.map { String(data: $0, encoding: .utf8) ?? "" }
        UserDefaults.standard.set(jsonStrings, forKey: "RecentJSONs")
    }
    
    // Load the buffer from UserDefaults
    func loadRecentJSONs() {
        if let jsonStrings = UserDefaults.standard.array(forKey: "RecentJSONs") as? [String] {
            sharedViewModel.recentJSONs = jsonStrings.compactMap { $0.data(using: .utf8) }
            print("Historial: \(sharedViewModel.recentJSONs.count)")
            jsonData = sharedViewModel.recentJSONs.reversed()[historyIndex]
        }
    }
    
    // Delete the buffer
    func deleteRecentJSONs() {
        sharedViewModel.recentJSONs.removeAll()
        UserDefaults.standard.removeObject(forKey: "RecentJSONs")
    }
    
    // Reset view to ask for JSON again
    func resetView() {
        dismissWindow(id: "ContainerView")
        shipmentID = ""
        jsonData = nil
        filteredJsonData = nil
        errorMessage = nil
        containers.removeAll()
        currentContainerIndex = 0
        boxCount = 0
        volumeEfficiency = 0.0
        model.secondaryVolumeIsShowing = false
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

