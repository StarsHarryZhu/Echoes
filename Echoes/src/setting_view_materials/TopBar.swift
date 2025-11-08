//
//  TopBar.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct TopBar: View {
    var size: CGFloat = 24
    let title: String
    var icon: String = "chevron.left"   // 默认左箭头（用于子页返回）
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onTap) {
                    Image(systemName: icon)
                        .font(.system(size: size, weight: .semibold))
                        .padding(8)
                        .background(Color(.systemGray6), in: Circle())
                }
                Spacer()
                Text(title)
                    .modifier(text_style(
                        size: size,
                    ))
                Spacer()
                // 右侧占位让标题居中
                Color.clear.frame(width: 34, height: 34).clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
    }
}
