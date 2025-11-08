//
//  SettingValueRow.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct SettingValueRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingRowBase(icon: icon, iconColor: iconColor, title: title) {
                HStack(spacing: 8) {
                    Text(value)
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
