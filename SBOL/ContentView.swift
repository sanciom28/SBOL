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
    @State private var shipmentID: String = ""
    @State private var errorMessage: String?
    @State private var ajustes: Bool = false
    @State private var volumeEfficiency: Double = 0.0
    @State private var historyIndex: Int = 0
    @State private var showHistory: Bool = false
    @State private var isAPILoading: Bool = false
    @State private var realBoxInfo: [BoxInfo] = []
    @State private var selectedBox = Set<BoxInfo.ID>()
    @State private var showCredentialPrompt: Bool = false
    @State private var showCredentialSheet: Bool = false
    @State private var tempUsername: String = ""
    @State private var tempPassword: String = ""
    @State private var appearStep: Int = 0
    
    @EnvironmentObject var containerViewModel: ContainerViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(ViewModel.self) var model
    @EnvironmentObject var sharedViewModel: RecentJSONsViewModel
    
    @AppStorage("scaleModifier") var scaleModifier: Int = 10
    @AppStorage("rotationSpeed") var rotationSpeed: Double = 3.0
    @AppStorage("maxStoredContainers") var maxStoredContainers: Int = 20
    @AppStorage("apiUsername") var apiUsername: String = ""
    @AppStorage("apiPassword") var apiPassword: String = ""
    
    var body: some View {
        @Bindable var model = model
        VStack {
            if jsonData == nil {
                if ajustes {
                    Text("Settings")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 40)
                    Text("Container scale")
                    Slider(value: Binding(
                        get: { Double(scaleModifier) },
                        set: { scaleModifier = Int($0) }
                    ), in: 5...15, step: 1)
                    .frame(width: 500)
                    if scaleModifier == 100 {
                        Text("Actual size")
                            .font(.system(size: 14))
                            .padding(.bottom, 20)
                    } else {
                        Text("\(scaleModifier)% of actual size")
                            .font(.system(size: 14))
                            .padding(.bottom, 20)
                    }
                    Text("Container rotation speed")
                    Slider(value: Binding(
                        get: { Double(rotationSpeed) },
                        set: { rotationSpeed = Double($0) }
                    ), in: 0...10, step: 1)
                    .frame(width: 500)
                    if rotationSpeed == 0 {
                        Text("Rotation disabled")
                            .font(.system(size: 14))
                            .padding(.bottom, 20)
                    } else {
                        Text("\(Int(rotationSpeed)) rotations per minute")
                            .font(.system(size: 14))
                            .padding(.bottom, 20)
                    }
                    Text("Amount of stored shipments")
                    Slider(value: Binding(
                        get: { Double(maxStoredContainers) },
                        set: { maxStoredContainers = Int($0) }
                    ), in: 1...100, step: 1)
                    .frame(width: 500)
                    if maxStoredContainers == 1 {
                        Text("1 shipment")
                            .font(.system(size: 14))
                            .padding(.bottom, 20)
                    } else {
                        Text("\(maxStoredContainers) shipments")
                            .font(.system(size: 14))
                            .padding(.bottom, 20)
                    }
                    Button("   Edit API credentials   ") {
                        tempUsername = apiUsername
                        tempPassword = apiPassword
                        showCredentialSheet = true
                    }
                    .font(.system(size: 22))
                    .padding(.top, 20)
                    Button("      Restore defaults      ") {
                        scaleModifier = 10
                        maxStoredContainers = 20
                        rotationSpeed = 3.0
                    }
                    .font(.system(size: 22))
                    .padding(.top, 12)
                    Button("Clear shipment history") {
                        deleteRecentJSONs()
                    }
                    .font(.system(size: 22))
                    .padding(12)
                } else {
                    Group {
                        Text("SBOL")
                            .font(.system(size: 150))
                            .fontDesign(.monospaced)
                            .bold()
                            .offset(z: 20)
                            .opacity(appearStep > 0 ? 1 : 0)
                            .offset(y: appearStep > 0 ? 0 : 40)
                            .animation(.easeOut(duration: 0.5), value: appearStep)
                            .onAppear {
                                dismissWindow(id: "ContainerView")
                            }
                            .padding(.top, -15)
                        Text("Spatial Bill of Lading")
                            .font(.system(size: 28))
                            .italic()
                            .padding(.bottom, 60)
                            .offset(z: 10)
                            .opacity(appearStep > 1 ? 1 : 0)
                            .offset(y: appearStep > 1 ? 0 : 40)
                            .animation(.easeOut(duration: 0.5).delay(0.1), value: appearStep)
                        Text("Enter shipment ID:")
                            .font(.headline)
                            .opacity(appearStep > 2 ? 1 : 0)
                            .offset(y: appearStep > 2 ? 0 : 40)
                            .animation(.easeOut(duration: 0.5).delay(0.2), value: appearStep)
                        TextField("Shipment ID", text: $shipmentID)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 500)
                            .padding()
                            .onSubmit {
                                fetchJSONFromAPI()
                            }
                            .opacity(appearStep > 3 ? 1 : 0)
                            .offset(y: appearStep > 3 ? 0 : 40)
                            .animation(.easeOut(duration: 0.5).delay(0.3), value: appearStep)
                        if isAPILoading == false {
                            Button("  Fetch from API  ") {
                                fetchJSONFromAPI()
                            }
                            .frame(width: 360, height: 80)
                            .font(.system(size: 24))
                            .disabled(shipmentID.isEmpty)
                            .padding(.bottom, -15)
                            .opacity(appearStep > 4 ? 1 : 0)
                            .offset(y: appearStep > 4 ? 0 : 40)
                            .animation(.easeOut(duration: 0.5).delay(0.4), value: appearStep)
                        } else {
                            ProgressView()
                                .padding()
                                .opacity(appearStep > 4 ? 1 : 0)
                                .animation(.easeOut(duration: 0.5).delay(0.4), value: appearStep)
                        }
                        Button("   Load recents   ") {
                            historyIndex = 0
                            loadRecentJSONs()
                            showHistory = true
                            if sharedViewModel.recentJSONs.isEmpty {
                                errorMessage = "No hay envíos recientes"
                                return
                            }
                        }
                        .frame(width: 360, height: 80)
                        .font(.system(size: 24))
                        .padding(.bottom, -15)
                        .opacity(appearStep > 5 ? 1 : 0)
                        .offset(y: appearStep > 5 ? 0 : 40)
                        .animation(.easeOut(duration: 0.5).delay(0.5), value: appearStep)
                        Button("   Load from file   ") {
                            showDocumentPicker = true
                        }
                        .sheet(isPresented: $showDocumentPicker) {
                            DocumentPickerView(jsonData: $jsonData)
                        }
                        .frame(width: 360, height: 80)
                        .font(.system(size: 24))
                        .padding(.bottom, 5)
                        .opacity(appearStep > 6 ? 1 : 0)
                        .offset(y: appearStep > 6 ? 0 : 40)
                        .animation(.easeOut(duration: 0.5).delay(0.6), value: appearStep)
                    }
                }
                
                Button(action: {
                    ajustes.toggle()
                }) {
                    Image(systemName: ajustes ? "xmark.circle.fill" : "gear")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                .frame(width: 30, height: 30)
                .opacity(appearStep > 7 ? 1 : 0)
                .offset(y: appearStep > 7 ? 0 : 40)
                .animation(.easeOut(duration: 0.5).delay(0.7), value: appearStep)
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            } else {
                // UI after JSON is loaded
                ZStack {
                    HStack(alignment: .top) {
                        VStack(spacing: 4) {
                            Text("Shipment details")
                                .font(.title)
                                .bold()
                                .padding()
                            
                            VStack(alignment: .leading) {
                                if shipmentID != "" {
                                    Text("Shipment ID: \(shipmentID)")
                                }
                                Text("Total containers: \(containerCount)")
                                Text("Current container: \(currentContainerIndex + 1) / \(containerCount)")
                                Text("Total boxes: \(boxCount)")
                                Text("Load efficiency: \(String(format: "%.2f", volumeEfficiency))%")
                                    .padding(.bottom, 10)
                            }
                            HStack {
                                Button(action: {
                                    selectedBox.removeAll()
                                    currentContainerIndex-=1
                                    model.secondaryWindowIsShowing = false
                                    loadAndRenderFromJSON() // Render container
                                    
                                }) {
                                    Image(systemName: "arrow.left")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }.padding()
                                    .disabled(currentContainerIndex == 0)
                                
                                Button(action: {
                                    selectedBox.removeAll()
                                    currentContainerIndex+=1
                                    model.secondaryWindowIsShowing = false
                                    loadAndRenderFromJSON() // Render container
                                    
                                }) {
                                    Image(systemName: "arrow.right")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                }.padding()
                                    .disabled(currentContainerIndex >= containerCount-1)
                            }
                            Toggle("  Show container  ", isOn: $model.secondaryWindowIsShowing)
                                .toggleStyle(.button)
                                .onChange(of: model.secondaryWindowIsShowing) { _, isShowing in
                                    selectedBox.removeAll()
                                    loadAndRenderFromJSON()
                                    if isShowing {
                                        openWindow(id: "ContainerView")
                                    } else {
                                        dismissWindow(id: "ContainerView")
                                    }
                                }.padding()
                            if showHistory {
                                Button(action: {
                                    selectedBox.removeAll()
                                    historyIndex -= 1
                                    loadRecentJSONs()
                                    showHistory = true
                                    loadAndRenderFromJSON()
                                }) {
                                    Text("Previous shipment")
                                }.disabled(historyIndex == 0)
                                
                                Button(action: {
                                    selectedBox.removeAll()
                                    historyIndex += 1
                                    loadRecentJSONs()
                                    showHistory = true
                                    loadAndRenderFromJSON()
                                }) {
                                    Text("    Next shipment    ")
                                }.disabled(historyIndex >= sharedViewModel.recentJSONs.count-1)
                                    .padding()
                            }
                            Spacer()
                            Button(" Return ") {
                                resetView()
                            }.padding()
                        }.padding()
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(15)
                        
                        Table(realBoxInfo, selection: $selectedBox) {
                            TableColumn("ID", value: \.id)
                                .width(160)
                            TableColumn("Name", value: \.name)
                            TableColumn("Count", value: \.count)
                                .width(130)
                                .alignment(.trailing)
                        }.padding()
                            .onChange(of: selectedBox) { oldSelection, newSelection in
                                if let selected = newSelection.first, let box = realBoxInfo.first(where: { $0.id == selected }) {
                                    dismissWindow(id: "ContainerView")
                                    filterJSONData(id: box.id)
                                    openWindow(id: "ContainerView")
                                }
                            }
                        Spacer(minLength: 20)
                    }
                    
                    RealityView { content in
                        loadAndRenderFromJSON()
                    }
                }
            }
        }.onAppear {
            model.primaryWindowIsShowing = true
        }.onDisappear {
            model.primaryWindowIsShowing = false
        }
        .alert(isPresented: $showCredentialPrompt) {
            Alert(
                title: Text("Credentials required"),
                message: Text("Please enter your API username and password to continue."),
                primaryButton: .default(Text("Continue"), action: {
                    tempUsername = apiUsername
                    tempPassword = apiPassword
                    showCredentialSheet = true
                }),
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showCredentialSheet) {
            VStack(spacing: 20) {
                Text("Edit API credentials")
                    .font(.title2)
                TextField("Username", text: $tempUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 400)
                SecureField("Password", text: $tempPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 400)
                    .padding(.bottom, 10)
                HStack {
                    Button("Cancel") {
                        showCredentialSheet = false
                    }
                    .padding(.horizontal, 16)
                    Button("Save") {
                        apiUsername = tempUsername
                        apiPassword = tempPassword
                        showCredentialSheet = false
                    }
                    .padding(.horizontal, 16)
                }
            }
            .frame(width: 450, height: 250)
            .padding()
        }
        .onAppear {
            appearStep = 0
            for i in 1...9 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
                    withAnimation { appearStep = i }
                }
            }
        }
        .onChange(of: errorMessage) { _, newValue in
            if newValue != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if errorMessage == newValue {
                        errorMessage = nil
                    }
                }
            }
        }
    }
    
    func loadAndRenderFromJSON(content: RealityKit.RealityViewContent? = nil) {
        guard let jsonData = jsonData else { return }
        
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
                
                realBoxInfo = []
                if let items = currentContainer["items"] as? [[String: Any]] {
                    for item in items {
                        let id = String(describing: item["product_code"] ?? "")
                        let name = String(describing: item["prd_description"] ?? "")
                        let count = String(describing: item["prod_amount"] ?? "")
                        realBoxInfo.append(BoxInfo(id: id, name: name, count: count))
                    }
                }
                
                if (currentContainer["locations"] != nil) {
                    containerViewModel.addRawJSON(json: currentContainer)
                }
                
            }
        } catch {
            errorMessage = "Error loading JSON: \(error.localizedDescription)"
        }
    }
    
    func fetchJSONFromAPI() {
        isAPILoading = true
        errorMessage = nil
        guard !apiUsername.isEmpty, !apiPassword.isEmpty else {
            showCredentialPrompt = true
            isAPILoading = false
            return
        }
        guard let shipmentNumber = Int(shipmentID) else {
            errorMessage = "Invalid shipment ID"
            isAPILoading = false
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
            DispatchQueue.main.async { errorMessage = "JSON encoding request error"; isAPILoading = false }
            return
        }
        
        let urlString = baseURL + jsonString
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { errorMessage = "Invalid API URL"; isAPILoading = false }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let credentials = apiUsername + ":" + apiPassword
        request.setValue("Basic " + Data(credentials.utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "Request error: \(error.localizedDescription)"
                    isAPILoading = false
                    return
                }
                guard let data = data else {
                    errorMessage = "Error receiving data"
                    isAPILoading = false
                    return
                }
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if jsonObject!["errormessage"] != nil || jsonObject?["waybill"] as! Int == 0 {
                        errorMessage = "Shipment not found"
                        isAPILoading = false
                        return
                    }
                } catch {
                    errorMessage = "Error parsing JSON: \(error.localizedDescription)"
                    isAPILoading = false
                    return
                }
                
                isAPILoading = false
                loadRecentJSONs()
                self.jsonData = data
                addToRecentJSONs(data)
            }
        }.resume()
    }
    
    func addToRecentJSONs(_ json: Data) {
        sharedViewModel.recentJSONs.removeAll(where: { $0 == json })
        sharedViewModel.recentJSONs.append(json)
        if sharedViewModel.recentJSONs.count > maxStoredContainers {
            sharedViewModel.recentJSONs.removeFirst()
        }
        saveRecentJSONs()
    }
    
    func saveRecentJSONs() {
        let jsonStrings = sharedViewModel.recentJSONs.map { String(data: $0, encoding: .utf8) ?? "" }
        UserDefaults.standard.set(jsonStrings, forKey: "RecentJSONs")
    }
    
    func loadRecentJSONs() {
        resetView()
        if let jsonStrings = UserDefaults.standard.array(forKey: "RecentJSONs") as? [String] {
            sharedViewModel.recentJSONs = jsonStrings.compactMap { $0.data(using: .utf8) }
            if 0 <= historyIndex && historyIndex < sharedViewModel.recentJSONs.count {
                jsonData = sharedViewModel.recentJSONs.reversed()[historyIndex]
            }
        }
    }
    
    func filterJSONData(id: String, content: RealityKit.RealityViewContent? = nil) {
        guard let jsonData = jsonData else { return }
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
               let containers = jsonObject["containers"] as? [[String: Any]] {
                let currentContainer = containers[currentContainerIndex]
                if let locations = currentContainer["locations"] as? String {
                    var boxDetails = locations.components(separatedBy: "\r").filter { !$0.isEmpty }
                    boxDetails.removeAll { boxDetail in
                        let values = boxDetail.components(separatedBy: ",")
                        return values.count > 2 && values[2] != id
                    }
                    let filteredLocations = boxDetails.joined(separator: "\r")
                    var modifiedContainer = currentContainer
                    modifiedContainer["locations"] = filteredLocations
                    containerViewModel.addRawJSON(json: modifiedContainer)
                }
            }
        } catch {
            errorMessage = "Error loading JSON: \(error.localizedDescription)"
        }
    }
    
    func deleteRecentJSONs() {
        sharedViewModel.recentJSONs.removeAll()
        UserDefaults.standard.removeObject(forKey: "RecentJSONs")
    }
    
    func resetView() {
        dismissWindow(id: "ContainerView")
        shipmentID = ""
        jsonData = nil
        errorMessage = nil
        containers.removeAll()
        currentContainerIndex = 0
        boxCount = 0
        volumeEfficiency = 0.0
        model.secondaryWindowIsShowing = false
        showHistory = false
        sharedViewModel.recentJSONs = []
    }
    
}
