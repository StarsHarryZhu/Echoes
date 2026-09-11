//
//  AboutUsView.swift
//  Echoes
//

import SwiftUI

/// 关于页：App 信息 + 版本号。
struct AboutUsView: View {

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Image(systemName: "camera.shutter.button")
                        .font(.system(size: 44))
                        .foregroundStyle(.tint)
                    Text(AppInfo.name)
                        .appText(24, weight: .bold)
                    Text(AppInfo.tagline)
                        .appText(14)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }

            Section("版本") {
                LabeledContent("版本号", value: version)
                LabeledContent("构建号", value: build)
            }

            Section("我们为什么做 Echoes") {
                Text(AppCopy.creatorsIntro)
                    .appText(15)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("关于 Echoes")
        .navigationBarTitleDisplayMode(.inline)
    }
}
