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
            
            Tab(tabview_words.photos, systemImage:tabview_images.photos){
                
            }
            Tab(tabview_words.emotion, systemImage:tabview_images.emotion){
                
            }
            Tab(tabview_words.camera, systemImage:tabview_images.camera){
                
            }
            Tab(tabview_words.memory, systemImage: tabview_images.memory){
                
            }
            Tab(tabview_words.home, systemImage: tabview_images.home){
                
            }
        }
    }
}


#Preview {
    ContentView()
}
