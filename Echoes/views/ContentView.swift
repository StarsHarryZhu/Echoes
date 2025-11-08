//
//  ContentView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

struct ContentView: View {
    @State private var showSettings = false
    @State private var selected = 0
    @State private var disable_tab = 1
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $selected) {
                    EmotionsView()
                        .tabItem {
                            Label(tabview_words.emotion,
                                  systemImage: tabview_images.emotion)
                        }
                        .tag(0)

                    Text("")
                        .tabItem {
                            Label("", systemImage: "")
                        }
                        .tag(1)

                    MemoriesView()
                        .tabItem {
                            Label(tabview_words.memory,
                                  systemImage: tabview_images.memory)
                        }
                        .tag(2)
                }
                .onChange(of: selected) { old, new in
                        if new == disable_tab {
                            
                            selected = old
                        }
                }

                // 中间悬浮相机按钮（保留你的实现）
                VStack {
                    Spacer()
                    button(
                        image: camera_button.image,
                        size: 70,
                        foregroundColor: .black
                    ) {
                        Task {
                            let camera = camera_control()
                            _ = await camera.capture()
                        }
                    }
                    .padding(.bottom, 25) // 贴近 Tab 栏上方
                }
                .ignoresSafeArea(edges: .bottom)
            }
            // 全局「设置」齿轮（常驻）
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .fullScreenCover(isPresented: $showSettings) {
                SettingsView() // 全屏
            }
            .sheet(isPresented: $showSettings) {
                SettingsView() // 占位设置页（见下）
            }
            // 统一设置导航栏标题字体（方案A）
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithDefaultBackground()
                // 大标题（靠左样式）
                if let font = UIFont(name: "SmileySans-Oblique", size: 34) {
                    appearance.largeTitleTextAttributes = [
                        .font: font,
                        .foregroundColor: UIColor.label
                    ]
                }
                // 如需也改小标题（inline）可取消注释：
                // if let small = UIFont(name: "SmileySans-Oblique", size: 18) {
                //     appearance.titleTextAttributes = [
                //         .font: small,
                //         .foregroundColor: UIColor.label
                //     ]
                // }
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}


#Preview {
    ContentView()
}
