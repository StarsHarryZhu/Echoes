//
//  ContentView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            TabView {
                Tab(tabview_words.photos, systemImage: tabview_images.photos) {
                    
                }
                Tab(tabview_words.emotion, systemImage: tabview_images.emotion) {
                    
                }
                Tab("", systemImage: "") {
                    
                }
                Tab(tabview_words.memory, systemImage: tabview_images.memory) {
                    
                }
                Tab(tabview_words.home, systemImage: tabview_images.home) {
                    
                }
            }
            VStack {
                Spacer()

                Button(action: {
                    Task {
                        let camera = camera_control()
                        let result = await camera.capture()
                        
//                        switch result{
//                            case .success(let image):{
//                                
//                            }
//                            case .cancel:{
//                                
//                            }
//                            case .exception:{
//
//                            }
//                        }
                        
                    }
                }) {
                    Image(systemName: camera_button.image)
                }
                .buttonStyle(button_style(size: 32,
                                          background_color: .black,
                                          foreground_color: .white))
                            
                .padding(.bottom, 25)
            }
            .ignoresSafeArea(edges: .bottom)
        }

    }
}


#Preview {
    ContentView()
}
