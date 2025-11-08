//
//  SettingRowBase.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import Foundation
import SwiftUI

struct SettingRowBase<RightContent: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder var right: RightContent

    var body: some View {
        HStack(spacing: 12) {
            IconBox(icon: icon, color: iconColor)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            right
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white.clipShape(RoundedRectangle(cornerRadius: 16)))
    }
}
