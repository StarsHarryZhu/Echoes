//
//  MemberRow.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/8.
//

import Foundation
import SwiftUI

struct MemberRow: View {
    private let name_size: CGFloat = 16
    private let role_size: CGFloat = 14
    let icon: String
    let name: String
    let role: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .modifier(text_style(
                        size: name_size,
                    ))
                    .font(.headline)
                Text(role)
                    .modifier(text_style(
                        size: role_size,
                    ))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
