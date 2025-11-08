//
//  AboutUs.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

private enum Subpage: Hashable {
    case creatorsIntro
}

// 二级页：About Us
struct AboutUsView: View {
    let onBack: () -> Void
    
    @State private var path = NavigationPath()
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                TopBar(title: "About Us", onTap: onBack)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // App 信息
                        SettingsCard(header: "App") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "camera.shutter.button") // TODO: 换你的 logo
                                        .font(.system(size: 28))
                                        .foregroundStyle(.black)
                                        .frame(width: 40, height: 40)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Echoes").font(.headline)
                                        Text("Capture emotions. Keep memories.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }

                                Divider()

                                HStack {
                                    Text("Version")
                                    Spacer()
                                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                        .foregroundStyle(.secondary)
                                }

                                Divider()

                                HStack {
                                    Text("Build")
                                    Spacer()
                                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 14)
                        }

                        // 三级入口：Creaters
                        SettingsCard(header: "About Creaters") {
                            NavigationLink(value: Subpage.creatorsIntro) {
                                HStack(spacing: 12) {
                                    IconBox(icon: "person", color: .black)
                                    Text("Creaters")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color.white.clipShape(RoundedRectangle(cornerRadius: 16)))
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Subpage.self) { page in
            switch page {
            case .creatorsIntro:
                RateUsView(onBack: { path.removeLast() })
            }
        }
    }
}

// 三级页：Creators Intro（可编辑＋持久化）
struct CreatorsIntroView: View {
    let onBack: () -> Void

    @AppStorage("creatorsIntroText") private var introText: String =
    """
Echoes is built by a small team who believe photos are more than pixels — they’re emotions and stories. We design calm, human-centered tools that help you capture feelings and revisit memories with care.
"""

    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                TopBar(title: "About Creaters", onTap: onBack)

                ScrollView {
                    VStack(spacing: 20) {

                        SettingsCard(header: "Team") {
                            VStack(alignment: .leading, spacing: 14) {
                                MemberRow(icon: "person.crop.circle.fill", name: "Harry Zhu", role: "Product & Design")
                                Divider()
                                MemberRow(icon: "brain.head.profile", name: "Echoes Lab", role: "Vision & ML")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                        }

                        SettingsCard(header: "Our Story") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(isEditing ? "Editing" : "Introduction")
                                        .font(.headline)
                                    Spacer()
                                    Button(isEditing ? "Done" : "Edit") {
                                        isEditing.toggle()
                                    }
                                    .font(.callout.weight(.semibold))
                                }

                                if isEditing {
                                    TextEditor(text: $introText)
                                        .frame(minHeight: 160)
                                        .padding(10)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.quaternaryLabel))
                                        )
                                } else {
                                    Text(introText)
                                        .font(.callout)
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MemberRow: View {
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
