//
//  EchoesApp.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

@main
struct EchoesApp: App {
    init() {
        let appearance = UITabBarAppearance()
        
        // 未选中状态字体样式
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.gray
        ]
        
        // 选中状态字体样式
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.boldSystemFont(ofSize: 15),
            .foregroundColor: UIColor.systemBlue
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
