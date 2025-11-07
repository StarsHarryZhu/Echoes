//
//  ContentView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView
        {
            Tab("home", systemImage: "house"){
                //Text("home")
            }
            Tab("photos", systemImage:"photo"){
                
            }
        }
    }
}

#Preview {
    ContentView()
}
