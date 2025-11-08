//
//  SettingNavRow.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct SettingNavRow: View {
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
                            .font(.callout)
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
