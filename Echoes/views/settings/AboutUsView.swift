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

            Section(L10n.aboutSectionVersion) {
                LabeledContent(L10n.aboutVersion, value: version)
                LabeledContent(L10n.aboutBuild, value: build)
            }

            Section(L10n.aboutWhyTitle) {
                Text(AppCopy.creatorsIntro)
                    .appText(15)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.settingsAboutApp)
        .navigationBarTitleDisplayMode(.inline)
    }
}
