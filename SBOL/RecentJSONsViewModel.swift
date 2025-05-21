//
//  SharedViewModel.swift
//  SBOL
//
//  Created by Matteo Sancio on 5/19/25.
//


import SwiftUI

class RecentJSONsViewModel: ObservableObject {
    @Published var recentJSONs: [Data] = []
        
    func clearRecentJSONs() {
        recentJSONs.removeAll()
        UserDefaults.standard.removeObject(forKey: "recentJSONs")
    }
}
