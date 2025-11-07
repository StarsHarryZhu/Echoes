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

        // 选中/未选中标题字体与颜色（UIKit 写法）
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont(name: "SmileySans-Oblique", size: 13) ?? UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.systemBlue
        ]
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont(name: "SmileySans-Oblique", size: 13) ?? UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.secondaryLabel
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
