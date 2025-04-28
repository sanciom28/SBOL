import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .bold()
                .padding()

            // Add your settings UI here
            Text("This is the settings page.")
                .font(.body)
                .padding()

            Spacer()
        }
        .navigationTitle("Settings")
    }
}

struct ContentView: View {
    @State private var showDocumentPicker = false
    @State private var jsonData: Data? = nil

    var body: some View {
        NavigationView {
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
                    Button("Cargar desde archivo") {
                        showDocumentPicker = true
                    }
                    .frame(width: 360, height: 80)
                    .font(.system(size: 24))
                } else {
                    Text("JSON Loaded")
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPickerView(jsonData: $jsonData)
            }
            .navigationTitle("Main View")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Circle().fill(Color.gray.opacity(0.2)))
                    }
                }
            }
        }
    }
}