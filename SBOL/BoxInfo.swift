//
//  BoxInfo.swift
//  SBOL
//
//  Created by Matteo Sancio on 6/3/25.
//

import SwiftUI

// Struct for table purposes
struct BoxInfo: Identifiable {
    var uuid = UUID()
    var id: String
    var name: String
    var count: String
}
