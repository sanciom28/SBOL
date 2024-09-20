//
//  BoxViewModel.swift
//  SBOL
//
//  Created by Matteo Sancio on 9/13/24.
//

import Foundation

func parseBoxes(from jsonString: String) -> [Box] {
    var boxes: [Box] = []
    
    // Split the locations string by \r (box separator)
    let rows = jsonString.components(separatedBy: "\r").filter { !$0.isEmpty }
    
    for row in rows {
        // Split each row by commas (field separator)
        let values = row.components(separatedBy: ",")
        
        if values.count >= 11 {  // Ensure we have enough data for a valid box
            if let length = Float(values[3]),
               let width = Float(values[4]),
               let height = Float(values[5]),
               let orientation = Float(values[7]),
               let x = Float(values[8]),
               let y = Float(values[9]),
               let z = Float(values[10]) {
                
                let box = Box(
                    length: length,
                    width: width,
                    height: height,
                    color: values[6],  // color as a string
                    orientation: orientation,
                    x: x,
                    y: y,
                    z: z
                )
                boxes.append(box)
            }
        }
    }
    
    return boxes
}

func loadBoxesData() -> [Box]? {
    guard let fileURL = Bundle.main.url(forResource: "SingleBox", withExtension: "json") else {
        print("File not found")
        return nil
    }
    
    do {
        let data = try Data(contentsOf: fileURL)
        let dataModel = try JSONDecoder().decode(DataModel.self, from: data)
        
        // We're assuming you want to process the first container (you can adjust for multiple containers)
        if let firstContainer = dataModel.containers.first {
            let boxes = parseBoxes(from: firstContainer.locations)
            return boxes
        }
        
        return nil
    } catch {
        print("Error loading or decoding JSON: \(error)")
        return nil
    }
}
