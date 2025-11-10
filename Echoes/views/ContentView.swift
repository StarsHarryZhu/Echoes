//
//  ContentView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

struct ContentView: View {
    @State private var show_settings = false
    @State private var selected = 0
    private let disabled_tab = 1

    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selected) {
                    EmotionsView()
                        .tabItem { Label(
                            tabview_words.emotion,
                            systemImage: tabview_images.emotion
                        )}
                        .tag(0)

                    // disabled middle tab (kept for spacing)
                    Text("")
                        .tabItem { Label("", systemImage: "") }
                        .tag(1)

                    MemoriesView()
                        .tabItem { Label(
                            tabview_words.memory,
                            systemImage: tabview_images.memory
                        )}
                        .tag(2)
                }
                .onChange(of: selected) { old, new in
                    if new == disabled_tab {
                        selected = old
                    }
                }

                // 中间悬浮相机按钮
                VStack {
                    Spacer()
                    button(image: camera_button.image, size: 70, foregroundColor: .black) {
                        Task {
                            await capture()
                        }
                    }
                    .padding(.bottom, 25)
                }
                .ignoresSafeArea(edges: .bottom)
            }

            // ✅ 自定义导航栏标题（左对齐 + 相机图标）
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左侧标题 + 图标
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.shutter.button")
                            .font(.system(size: 20))
                            .foregroundStyle(.primary)

                        Text("Echoes")
                            .modifier(text_style(
                                size: 25,
                            ))
                            .bold()

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // 右侧齿轮按钮
                ToolbarItem(placement: .topBarTrailing) {
                    Button { show_settings = true } label: {
                        Image(systemName: "gearshape")
                            .imageScale(.large)
                    }
                    .buttonStyle(.plain)
                }
            }

            // ✅ 全屏设置页
            .fullScreenCover(isPresented: $show_settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
