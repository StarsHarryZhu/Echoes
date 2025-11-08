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
                Tab(tabview_words.emotion, systemImage: tabview_images.emotion) {
                    EmotionsView()
                }
                Tab("", systemImage: "") {
                    
                }
                Tab(tabview_words.memory, systemImage: tabview_images.memory) {
                    MemoriesView()
                }
            }

            VStack {
                Spacer()
                button(
                    image: camera_button.image,
                    size: 70,
                    foregroundColor: .black,
                ) {
                    Task {
                        let camera = camera_control()
                        _ = await camera.capture()
                    }
                }
                .padding(.bottom, 25) // ✅ 让它正好贴着 tab 栏上方
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    ContentView()
}
