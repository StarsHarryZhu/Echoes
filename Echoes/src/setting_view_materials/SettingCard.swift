//
//  SettingCard.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct SettingsCard<Content: View>: View {
    var size: CGFloat = 16
    let header: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(header)
                .modifier(text_style(
                    size: size
                ))

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
        }
    }
}
