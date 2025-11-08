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
    private let app_name_size: CGFloat = 18
    private let app_subtitle_size: CGFloat = 14
    private let others: CGFloat = 16
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
                                    Image(systemName: "camera.shutter.button")
                                        .font(.system(size: 28))
                                        .foregroundStyle(.black)
                                        .frame(width: 40, height: 40)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Echoes")
                                            .modifier(text_style(
                                                size: app_name_size,
                                            ))
                                        Text("Capture emotions. Keep memories.")
                                            .modifier(text_style(
                                                size: app_subtitle_size,
                                            ))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }

                                Divider()

                                HStack {
                                    Text("Version")
                                        .modifier(text_style(
                                            size: others,
                                        ))
                                    Spacer()
                                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                        .modifier(text_style(
                                            size: others,
                                        ))
                                        .foregroundStyle(.secondary)
                                }

                                Divider()

                                HStack {
                                    Text("Build")
                                        .modifier(text_style(
                                            size: others,
                                        ))
                                    Spacer()
                                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-")
                                        .modifier(text_style(
                                            size: others,
                                        ))
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
                                        .modifier(text_style(
                                            size: others,
                                        ))
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
                CreatersIntroView()   // 不再传 onBack；内部用 dismiss()
            }
        }
    }
}
