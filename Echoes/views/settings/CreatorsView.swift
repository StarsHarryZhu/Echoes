//
//  CreatorsView.swift
//  Echoes
//

import SwiftUI

/// 开发团队页。
struct CreatorsView: View {

    private static let members: [(name: String, role: String)] = [
        ("Hui Jin", "Product & Design"),
        ("Huanyi Zhu", "Product & Design"),
    ]

    var body: some View {
        List {
            Section("团队") {
                ForEach(Self.members, id: \.name) { member in
                    row(name: member.name, role: member.role)
                }
            }

            Section("我们的想法") {
                Text(AppCopy.creatorsIntro)
                    .appText(15)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("开发团队")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(name: String, role: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).appText(16, weight: .semibold)
                Text(role).appText(13).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
