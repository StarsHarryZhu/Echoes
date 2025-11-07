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
                            .font(.system(size: 14))// 修改字体
                    }
                }

                Tab {
                } label: {
                    VStack {
                        Image(systemName: tabview_images.emotion)
                        Text(tabview_words.emotion)
                            .font(.system(size: 14)) // 改字体
                    }
                }

                Tab {
                } label: {
                    VStack {
                        Image(systemName: "")   // 空占位
                        Text("")                // 空占位
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
