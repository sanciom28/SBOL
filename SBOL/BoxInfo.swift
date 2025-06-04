//
//  BoxInfo.swift
//  SBOL
//
//  Created by Matteo Sancio on 6/3/25.
//

import SwiftUI

// Struct for table purposes
struct BoxInfo: Identifiable {
    var id = UUID()
    
    var count: String
    var color: String
    var dimensions: String
    
//    var count: Int
//    var color: UIColor
//    var dimensions: SIMD3<Float> // (length, height, width)
}
