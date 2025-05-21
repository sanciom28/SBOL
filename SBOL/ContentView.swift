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
    @State private var ajustes: Bool = false
    
    @EnvironmentObject var containerViewModel: ContainerViewModel
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Environment(ViewModel.self) var model
    
    @EnvironmentObject var sharedViewModel: RecentJSONsViewModel
    
    @AppStorage("scaleModifier") var scaleModifier: Int = 10
    //@State private var recentJSONs: [Data] = [] // Buffer for recent JSONs
    @AppStorage("maxStoredContainers") var maxStoredContainers: Int = 20
    
    @State private var filteredJsonData: Data? = nil
    
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
                if ajustes {
                    Text("Congifuración")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                    Text("Escala del contenedor")
                        .font(.headline)
                    Slider(value: Binding(
                        get: { Double(scaleModifier) },
                        set: { scaleModifier = Int($0) }
                    ), in: 1...100, step: 1)
                    .padding()
                    Text("\(scaleModifier)%")
                        .padding(.top, -10)
                    
                    Text("Cantidad de contenedores guardados en historial")
                    Slider(value: Binding(
                        get: { Double(maxStoredContainers) },
                        set: { maxStoredContainers = Int($0) }
                    ), in: 1...100, step: 1)
                    .padding()
                    Text("\(maxStoredContainers) contenedores")
                        .padding(.top, -10)
                    Button("Restaurar valores por defecto") {
                        print("Scale value before restoring: \(scaleModifier)")
                        print("Max buffer value before restoring: \(maxStoredContainers)")
                        scaleModifier = 10
                        maxStoredContainers = 20
                    }.padding(.top, 10)
                    Button("Borrar historial de contenedores") {
                        print(sharedViewModel.recentJSONs)
                        deleteRecentJSONs()
                        print(sharedViewModel.recentJSONs)
                    }.padding()
                } else {
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
                        //loadRecentJSONs()
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
                    
                    Button("Cargar último contenedor") {
                        loadRecentJSONs()
                        print("Recent JSONs: \(sharedViewModel.recentJSONs.count)")
                        if sharedViewModel.recentJSONs.isEmpty {
                            errorMessage = "No hay contenedores recientes"
                            return
                        }
                        jsonData = sharedViewModel.recentJSONs.last
                        loadAndRenderFromJSON(content: nil)
                    }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
                    
                    
                }
                
                Button(action: {
                    ajustes.toggle()
                }) {
                    Image(systemName: ajustes ? "xmark.circle.fill" : "gearshape.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        
                }
                .frame(width: 30, height: 30)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
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
                    List(boxData.sorted(by: { $0.key < $1.key }), id: \.key) { boxID, boxInfo in
                        HStack {
                            Text("ID: \(boxID)")
                                .font(.headline)
                            Spacer()
                            VStack(alignment: .leading) {
                                Text("Count: \(boxInfo.count)")
                                Text("Color: \(boxInfo.color.description)")
                                Text("Dimensions: \(boxInfo.dimensions.x) x \(boxInfo.dimensions.y) x \(boxInfo.dimensions.z)")
                            }
                        }
                        .padding()
                    }
                    
                    Button("Volver") {
                        resetView()
                    }
                    .onDisappear {
                        model.secondaryVolumeIsShowing = false
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
                //                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                
                
            }
            
        }
        
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView(jsonData: $jsonData)
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
    
    func loadAndRenderFromJSON(content: RealityKit.RealityViewContent?) {
        guard var jsonData = jsonData else { return }
        
        if let filteredData = filteredJsonData {
            jsonData = filteredData
        }
        
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
        if sharedViewModel.recentJSONs.count >= maxStoredContainers {
            sharedViewModel.recentJSONs.removeFirst()
        }
        if sharedViewModel.recentJSONs.contains(json) {
            return // Avoid adding duplicates
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
            print("OG Historial: \(jsonStrings)")
            print("Historial: \(sharedViewModel.recentJSONs.count)")
        }
    }
    
    // Delete the buffer
    func deleteRecentJSONs() {
        sharedViewModel.recentJSONs.removeAll()
        UserDefaults.standard.removeObject(forKey: "RecentJSONs")
    }
    
    // Reset view to ask for JSON again
    func resetView() {
        shipmentID = ""
        jsonData = nil
        filteredJsonData = nil
        errorMessage = nil
        containers.removeAll()
        currentContainerIndex = 0
        boxCount = 0
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

