//
//  MemberRow.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/8.
//

import Foundation
import SwiftUI

struct MemberRow: View {
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
                Text(name).font(.headline)
                Text(role).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}
