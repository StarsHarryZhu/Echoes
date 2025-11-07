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
                Tab {
                } label: {
                    VStack {
                        Image(systemName: tabview_images.photos)
                        Text(tabview_words.photos)
                            .font(.system(size: 14))
                    }
                }

                Tab {
                } label: {
                    VStack {
                        Image(systemName: tabview_images.emotion)
                        Text(tabview_words.emotion)
                            .font(.system(size: 14))
                    }
                }

                Tab {
                } label: {
                    VStack {
                        Image(systemName: "")
                        Text("")
                    }
                }

                Tab {
                } label: {
                    VStack {
                        Image(systemName: tabview_images.memory)
                        Text(tabview_words.memory)
                            .font(.system(size: 14))
                    }
                }

                Tab {
                } label: {
                    VStack {
                        Image(systemName: tabview_images.home)
                        Text(tabview_words.home)
                            .font(.system(size: 14))
                    }
                }
            }

            VStack {
                Spacer()

                Button(action: {
                    Task {
                        let camera = camera_control()
                        let result = await camera.capture()
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
        // 👇 在这里打印系统所有字体，确认自定义字体是否加载成功
        .onAppear {
            for family in UIFont.familyNames.sorted() {
                print("Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("  Font: \(name)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
