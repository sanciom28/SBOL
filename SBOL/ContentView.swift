//
//  ContentView.swift
//  SBOL
//
//  Created by Matteo Sancio on 8/31/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

//struct ContentView: View {
//
//    @StateObject var viewModel = BoxViewModel()
//
//        var body: some View {
//            VStack {
//                if let containers = viewModel.boxesData?.boxes {
//                    // Example of using the data in your UI
//                    ForEach(containers.indices, id: \.self) { index in
//                        Text("Box \(index + 1): Width \(containers[index].width), Height \(containers[index].height), Depth \(containers[index].depth)")
//                    }
//                } else {
//                    Text("Loading...")
//                }
//            }
//            .onAppear {
//                // Optionally load from URL if needed
//                // viewModel.loadJSONFromURL("https://example.com/data.json")
//            }
//        }
//}

struct ContentView: View {
    @State private var boxEntities: [Entity] = []

    var body: some View {
        RealityView { content in
            // Create a parent entity to hold all the box entities
            let parentEntity = Entity()

            // Load and add the 3D boxes
            if let boxes = loadBoxesData() {
                print(boxes)
                let entities = createBoxEntities(from: boxes)
                for entity in entities {
                    parentEntity.addChild(entity)
                }
            }


            // Position the parent entity (camera) within view
            parentEntity.position = [0, 0, -2]  // Adjust the z-position to bring the boxes into view

            // Add the parent entity to the scene
            content.add(parentEntity)
        }
    }
}

#Preview(windowStyle: .automatic) {
            
    ContentView()
        .environment(AppModel())
}
