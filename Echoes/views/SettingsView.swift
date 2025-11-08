//
//  SettingsView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI
import StoreKit // RateUsView 需要

// 二级页路由
enum Subpage: Hashable {
    case about, feedback, rate
}

// MARK: - 全屏设置页（白底卡片布局）— 采用 push（右进左出）
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // 示例开关/选项（持久化）
    @AppStorage("simpleMode")      private var simpleMode = false
    @AppStorage("stabilizer")      private var stabilizer = true
    @AppStorage("grid")            private var grid = true
    @AppStorage("level")           private var level = true
    @AppStorage("storageAlert")    private var storageAlert = true
    @AppStorage("recordMode")      private var recordMode = 0 // 0: 仅录制原片
    @AppStorage("cacheSizeText")   private var cacheSizeText = "51.38MB"

    // ✅ push 用的导航路径
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(.systemBackground).ignoresSafeArea() // 白底

                VStack(spacing: 16) {
                    // 顶部导航（自定义，居中标题）
                    TopBar(title: "Settings", icon: "chevron.down") {
                        dismiss() // 关闭整个设置页（通常是从 fullScreenCover 弹出的）
                    }

                    ScrollView {
                        VStack(spacing: 20) {

                            // MARK: Capture
                            SettingsCard(header: "Capture") {
                                SettingToggleRow(icon: "square.grid.3x3", iconColor: .black, title: "Preview Grid", isOn: $grid)
                                Divider()
                                SettingToggleRow(icon: "line.diagonal", iconColor: .black, title: "Gradienter", isOn: $level)
                            }

                            // MARK: 性能
                            SettingsCard(header: "性能") {
                                SettingNavRow(icon: "slider.horizontal.3", iconColor: .black, title: "性能设置") {
                                    // path.append(.performance) // 需要时再加
                                }
                            }

                            // MARK: 录制模式
                            SettingsCard(header: "录制模式") {
                                SettingNavRow(icon: "cube.box", iconColor: .black, title: "录制模式", detail: recordModeText) {
                                    // path.append(.recordMode) // 需要时再加
                                }
                            }

                            // MARK: 通用
                            SettingsCard(header: "通用") {
                                SettingNavRow(icon: "person.badge.plus", iconColor: .black, title: "Personal Infomation") { }
                                Divider()
                                SettingValueRow(icon: "trash", iconColor: .red, title: "Clear Cache", value: cacheSizeText) {
                                    // 执行清理动作后，更新 cacheSizeText
                                }
                            }

                            // MARK: About（→ push 子页）
                            SettingsCard(header: "About") {
                                SettingNavRow(icon: "info.circle", iconColor: .black, title: "About us") {
                                    path.append(Subpage.about)
                                }
                                Divider()
                                SettingNavRow(icon: "envelope.badge", iconColor: .black, title: "Feedback and Suggestions") {
                                    path.append(Subpage.feedback)
                                }
                                Divider()
                                SettingNavRow(icon: "star", iconColor: .black, title: "Go Score") {
                                    path.append(Subpage.rate)
                                }
                            }

                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            // ✅ 注册子页（右进左出动画）
            .navigationDestination(for: Subpage.self) { page in
                switch page {
                case .about:
                    AboutUsView(onBack: { path.removeLast() })
                case .feedback:
                    FeedbackView(onBack: { path.removeLast() })
                case .rate:
                    RateUsView(onBack: { path.removeLast() })
                }
            }
            // 使用自定义 TopBar，隐藏系统导航栏
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var recordModeText: String {
        switch recordMode {
        case 0: return "仅录制原片"
        default: return "自定义"
        }
    }
}

// MARK: - 顶部条（支持左箭头或下拉）
private struct TopBar: View {
    let title: String
    var icon: String = "chevron.left"   // 默认左箭头（用于子页返回）
    var onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onTap) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(8)
                        .background(Color(.systemGray6), in: Circle())
                }
                Spacer()
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                // 右侧占位让标题居中
                Color.clear.frame(width: 34, height: 34).clipShape(Circle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
        }
    }
}

// MARK: - 卡片容器
private struct SettingsCard<Content: View>: View {
    let header: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(header)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.leading, 6)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
        }
    }
}

// MARK: - 行组件
private struct SettingRowBase<RightContent: View>: View {
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

private struct IconBox: View {
    let icon: String
    let color: Color
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
            Image(systemName: icon)
                .foregroundStyle(color)
        }
        .frame(width: 34, height: 34)
    }
}

private struct SettingToggleRow: View {
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

private struct SettingNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var detail: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingRowBase(icon: icon, iconColor: iconColor, title: title) {
                HStack(spacing: 8) {
                    if let detail {
                        Text(detail)
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct SettingValueRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingRowBase(icon: icon, iconColor: iconColor, title: title) {
                HStack(spacing: 8) {
                    Text(value)
                        .foregroundStyle(.secondary)
                        .font(.callout)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}

//////////////////////////////////////////////////////////
// MARK: - 二级页面（push，左箭头返回）
//////////////////////////////////////////////////////////

// A) About Us
struct AboutUsView: View {
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                TopBar(title: "About Us", onTap: onBack)

                ScrollView {
                    VStack(spacing: 20) {
                        SettingsCard(header: "App") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "app.gift.fill")
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
                                .navigationBarBackButtonHidden(true)
                                .navigationBarTitleDisplayMode(.inline)
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

                        SettingsCard(header: "Links") {
                            VStack(spacing: 0) {
                                LinkRow(title: "Privacy Policy", url: URL(string: "https://example.com/privacy")!)
                                Divider()
                                LinkRow(title: "Terms of Service", url: URL(string: "https://example.com/terms")!)
                                Divider()
                                LinkRow(title: "Official Website", url: URL(string: "https://example.com")!)
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private struct LinkRow: View {
        let title: String
        let url: URL
        var body: some View {
            Link(destination: url) {
                HStack {
                    Text(title).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.white.clipShape(RoundedRectangle(cornerRadius: 16)))
            }
            .buttonStyle(.plain)
        }
    }
}

// B) Feedback
struct FeedbackView: View {
    let onBack: () -> Void
    @State private var email: String = ""
    @State private var subject: String = ""
    @State private var content: String = ""
    @State private var includeDiagnostics = true
    @State private var submitted = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                TopBar(title: "Feedback", onTap: onBack)

                ScrollView {
                    VStack(spacing: 20) {

                        SettingsCard(header: "Contact") {
                            VStack(spacing: 12) {
                                TextField("Email (optional)", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .padding(12)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.quaternaryLabel)))
                                    .padding(.horizontal, 14)
                                    .padding(.top, 14)

                                TextField("Subject", text: $subject)
                                    .padding(12)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.quaternaryLabel)))
                                    .padding(.horizontal, 14)
                                    .padding(.bottom, 14)
                            }
                        }
                        
                        .navigationBarBackButtonHidden(true)
                        .navigationBarTitleDisplayMode(.inline)
                        
                        SettingsCard(header: "Message") {
                            TextEditor(text: $content)
                                .frame(minHeight: 160)
                                .padding(12)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.quaternaryLabel)))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                        }

                        SettingsCard(header: "Options") {
                            SettingToggleRow(icon: "wrench.and.screwdriver", iconColor: .black, title: "Include Diagnostics", isOn: $includeDiagnostics)
                        }

                        Button {
                            // TODO: 发送到你的服务端 / 邮件
                            submitted = true
                        } label: {
                            Text("Submit")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.black, in: RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .alert("Thanks!", isPresented: $submitted) {
                            Button("OK", role: .cancel) { onBack() }
                        } message: {
                            Text("We’ve received your feedback.")
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

// C) Go Score（评分）
struct RateUsView: View {
    let onBack: () -> Void
    @Environment(\.requestReview) private var requestReview // iOS 16+

    // 如果用跳转 App Store，请把你的 appID 换上
    private let appID = "0000000000" // ← 替换为你的 App Store ID

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                TopBar(title: "Rate Us", onTap: onBack)

                VStack(spacing: 20) {
                    SettingsCard(header: "Support Echoes") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("If you like Echoes, a 5-star rating really helps! ✨")
                                .padding(.horizontal, 14)
                                .padding(.top, 14)
                            
                .navigationBarBackButtonHidden(true)
                .navigationBarTitleDisplayMode(.inline)
                            

                            HStack(spacing: 12) {
                                Button {
                                    // 方式 1：系统内评分弹窗（频率受系统控制）
                                    requestReview()
                                } label: {
                                    Text("Rate In-App")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.black, in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(.white)
                                }

                                Button {
                                    // 方式 2：跳转到 App Store
                                    if let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    Text("Open App Store")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                                        .foregroundStyle(.primary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 14)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}
