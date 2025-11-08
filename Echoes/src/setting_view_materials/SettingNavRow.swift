//
//  SettingNavRow.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct SettingNavRow: View {
    var size: CGFloat = 16
    let icon: String
    let iconColor: Color
    let title: String
    var detail: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingRowBase(icon: icon, iconColor: iconColor, title: title) {
                HStack(spacing: 8) {
                    if let detail {
                        Text(detail)
                            .foregroundStyle(.secondary)
                            .modifier(text_style(
                                size: 16,
                            ))
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
