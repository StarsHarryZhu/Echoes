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
    @Environment(\.dismiss) private var dismiss   // 用系统 dismiss 返回更安全

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                // 顶部返回：仍调用父层传入的 onBack（如果你愿意也可以改成 { dismiss() }）
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
        // 由最近的 NavigationStack 负责 push；这里注册目的地即可
        .navigationDestination(for: Subpage.self) { page in
            switch page {
            case .creatorsIntro:
                CreatorsIntroView()   // 不再传 onBack；内部用 dismiss()
            }
        }
    }
}

// 三级页：Creators Intro（只读版）
struct CreatorsIntroView: View {
    @Environment(\.dismiss) private var dismiss

    private let introText: String =
    """
Echoes is built by a small team who believe photos are more than pixels — they’re emotions and stories. We design calm, human-centered tools that help you capture feelings and revisit memories with care.
"""

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                TopBar(title: "About Creaters", onTap: { dismiss() })

                ScrollView {
                    VStack(spacing: 20) {

                        SettingsCard(header: "Team") {
                            VStack(alignment: .leading, spacing: 14) {
                                MemberRow(icon: "person.crop.circle.fill", name: "Hui Jin", role: "Product & Design")
                                Divider()
                                MemberRow(icon: "person.crop.circle.fill", name: "Huanyi Zhu", role: "Product & Design")
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                        }

                        SettingsCard(header: "Our Story") {
                            Text(introText)
                                .font(.callout)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
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
