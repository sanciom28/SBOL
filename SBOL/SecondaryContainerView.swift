//
//  SecondaryVolumeView 2.swift
//  SBOL
//
//  Created by Matteo Sancio on 4/11/25.
//


//
//  SecondaryVolumeView.swift
//  SBOL
//
//  Created by Matteo Sancio on 3/24/25.
//


import SwiftUI

struct SecondaryContainerView: View {
    
    @Environment(ViewModel.self) private var model
    
    var body: some View {
    
        ZStack(alignment: .bottom) {
            //ContainerView()
            
            Text("This is a volume")
                .padding()
                .glassBackgroundEffect(in: .capsule)
        }
        // esto no lo necesito ya que jsondata = nil representa lo mismo
        .onDisappear {
            model.secondaryVolumeIsShowing.toggle()
        }
        
    }
}
