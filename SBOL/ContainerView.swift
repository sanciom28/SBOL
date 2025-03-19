//
//  ContainerView.swift
//  SBOL
//
//  Created by Matteo Sancio on 3/19/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContainerView: View {
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
           NavigationSplitView {
               VStack {
                   Button(action: {
                       dismissWindow(id: "ContainerView")
                       print("Show container Window")
                   }) {
                       Text("Dismiss container Window")
                           .font(.headline)
                           .padding()
                           .background(Color.blue)
                           .foregroundColor(.white)
                           .cornerRadius(10)
                   }
                   .buttonStyle(.plain)
               }
               .frame(maxWidth: .infinity, alignment: .top)
               .navigationTitle("Sidebar")
           } detail: {
               Text("Detail")
           }
           
       }
   }
