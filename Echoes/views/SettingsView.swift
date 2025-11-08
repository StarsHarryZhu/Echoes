//
//  SettingsView.swift
//  Echoes
//
//  Created by Harry Zhu on 2025/11/7.
//

import SwiftUI

// MARK: - 全屏设置页（白底卡片布局）
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

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea() // 白底

            VStack(spacing: 16) {
                // 顶部导航（自定义，居中标题）
                TopBar(title: "Setting") {
                    dismiss()
                }

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: 拍摄
                        SettingsCard(header: "Capture") {
        
                            Divider()
                            SettingToggleRow(icon: "square.grid.3x3", iconColor: .black, title: "Preview Grid", isOn: $grid)
                            Divider()
                            SettingToggleRow(icon: "line.diagonal", iconColor: .black, title: "Gradienter", isOn: $level)
                           
                        }

                        // MARK: 性能
                        SettingsCard(header: "性能") {
                            SettingNavRow(icon: "slider.horizontal.3", iconColor: .black, title: "性能设置") {
                                // push 详情页或弹窗
                            }
                        }

                        // MARK: 录制模式
                        SettingsCard(header: "录制模式") {
                            SettingNavRow(icon: "cube.box", iconColor: .black, title: "录制模式", detail: recordModeText) {
                                // 这里可进入选择页
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

                        // MARK: 关于
                        SettingsCard(header: "About") {
                            SettingNavRow(icon: "info.circle", iconColor: .black, title: "About us") { }
                            Divider()
                            SettingNavRow(icon: "envelope.badge", iconColor: .black, title: "Feedback and Suggestions") { }
                            Divider()
                            SettingNavRow(icon: "star", iconColor: .black, title: "Go Score") { }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private var recordModeText: String {
        switch recordMode {
        case 0: return "仅录制原片"
        default: return "自定义"
        }
    }
}

// MARK: - 顶部条
private struct TopBar: View {
    let title: String
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "chevron.down")
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
