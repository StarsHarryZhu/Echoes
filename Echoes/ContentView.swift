//
//  ContentView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            
            Tab("photos", systemImage:"photo"){
                
            }
            Tab("emotions", systemImage:"person.fill"){
                
            }
            Tab("my memories", systemImage: "memories"){
            }
            Tab("home", systemImage: "house"){
                //Text("home")
            }
        }
    }
}


#Preview {
    ContentView()
}
