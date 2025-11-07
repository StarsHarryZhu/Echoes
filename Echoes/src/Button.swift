//
//  UnitType.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI
import UIKit


struct button: View {
    var image: String = camera_button.image
    var size: CGFloat = 60
    var foregroundColor: Color = .black
    var action: () -> Void = {}

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action() // 直接执行动作，不做动画
        }) {
            Image(systemName: image)
                .font(.system(size: size * 0.4))
                .frame(width: size, height: size)
                .foregroundColor(foregroundColor)
                .background(.ultraThinMaterial) // ✅ iOS 26 “玻璃”效果
                .clipShape(Circle())
                .shadow(radius: 5)
                .overlay(
                    Circle()
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0) // ✅ 点击缩放动画
        }
        .buttonStyle(.plain) // 避免默认高亮灰色
    }
}
