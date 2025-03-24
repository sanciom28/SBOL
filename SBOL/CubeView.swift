//
//  CubeView.swift
//  SBOL
//
//  Created by Matteo Sancio on 3/24/25.
//

import SwiftUI
import RealityKit

struct CubeView: View {
    
    @State private var angle: Angle = .degrees(0)
    
    var body: some View {
    
        VStack(spacing: 18.0) {
            Model3D(named: "GlassCube") { model in
                switch model {
                case .empty:
                    ProgressView()
                    
                case .success(let resolvedModel3D):
                    resolvedModel3D
                        .scaleEffect(0.4)
                        .rotation3DEffect(angle, axis: .x)
                        .rotation3DEffect(angle, axis: .y)
                        .animation(.linear(duration: 18).repeatForever(), value: angle)
                        .onAppear {
                            angle = .degrees(359)
                        }
                        
                case .failure(let error):
                    Text(error.localizedDescription)
                    
                @unknown default:
                    EmptyView()
                }
            }
        }
        
    }
}

#Preview {
    CubeView()
}
