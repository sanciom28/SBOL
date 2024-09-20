//
//  BoxModel.swift
//  SBOL
//
//  Created by Matteo Sancio on 9/13/24.
//

import Foundation

struct Box {
    let length: Float
    let width: Float
    let height: Float
    let color: String
    let orientation: Float
    let x: Float
    let y: Float
    let z: Float
}

struct Container: Codable {
    let locations: String
    let cont_totalboxes: Int
}

struct DataModel: Codable {
    let containers: [Container]
}
     
