//
//  SettingToggleRow.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct SettingToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    var trailingInfoIcon: String? = nil

    var body: some View {
        SettingRowBase(icon: icon, iconColor: iconColor, title: title) {
            HStack(spacing: 8) {
                if let trailingInfoIcon {
                    Image(systemName: trailingInfoIcon)
                        .foregroundStyle(.secondary)
                }
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.blue)
            }
        }
    }
}
